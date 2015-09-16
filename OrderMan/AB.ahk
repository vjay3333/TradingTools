/*
  Copyright (C) 2015  SpiffSpaceman

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>
*/

installHotkeys(){
	global HKEntryPrice, HKStopPrice
	
	if( HKEntryPrice != "" && HKEntryPrice != "ERROR")
		Hotkey, %HKEntryPrice%, getEntryPriceFromAB	
	
	if( HKStopPrice != "" && HKStopPrice != "ERROR")
		Hotkey, %HKStopPrice%, getStopPriceFromAB	
}

getEntryPriceFromAB(){
	price := getPriceFromAB()
	if( price > 0 ){
		setEntryPrice( price )
		guessDirection()
	}
}

getStopPriceFromAB(){
	price := getPriceFromAB()
	if( price > 0 ){
		setStopPrice( price )
		guessDirection()
	}
}

guessDirection(){
	global EntryPrice, StopPrice
	
	setDirection( EntryPrice>StopPrice ? "B" : "S" )
}

/*
	Called by HK
	Get price from line under cursor if found, else get from tooltip text
*/
getPriceFromAB(){
	IfWinActive, OrderMan
		WinActivate, ahk_class AmiBrokerMainFrameClass
			
	IfWinActive, ahk_class AmiBrokerMainFrameClass
	{	
		BlockInput, MouseMove
		price := getPriceFromLine()
		if( price <= 0 )
			price := getPriceAtCursorTooltip()
		BlockInput, MouseMoveOff

		return roundToTickSize( price )		
	}
	else
		return -1
}

/*
	Selects line and opens properties. Price copied from start price
*/
getPriceFromLine(){
	
	Click 1																// Open trendline / HL properties. Click to Select + Alt-Enter
	Send {Alt down}{Enter}{Alt up}	
	
	Loop, 8{															// Try to hide window as soon as possible. WinWait seems to take too long
		Sleep 25
		WinSet,Transparent, 1, Properties, Start Y:
		IfWinExist, Properties, Start Y:
			break
	}	
	
	WinWait, Properties, Start Y:, 1
	WinSet,Transparent, 1, Properties, Start Y:
	
	IfWinExist, Properties, Start Y:
	{
		ControlGet, price, Line, 1, Edit1, Properties, Start Y:			// Get Start Price
		WinClose, Properties, Start Y:	
		return price
	}
	
	return -1
}

/*
	Tries to trigger tooltip in Amibroker and copies price using Value property
	Tooltip text row format is assumed to be either "Value = 7747.650" or "Begin:     09-09-2015 09:44:59, Value: 7785.28"
*/
getPriceAtCursorTooltip(){
	
	SendMode Event														// Input mode moves cursor immediately - Tooltip open is unreliable
	Loop, 5 {
		
		MouseMove, 15, 0, 25, R											// Move a bit to trigger tooltip
		WinWait, ahk_class tooltips_class32,, 1
		ControlGetText, tt_text,, ahk_class tooltips_class32			
		MouseMove, -15, 0,, R
		
		if( tt_text != ""){			
			break
		}
	}
	SendMode Input	

	if( tt_text == "" )
		return ""	

	Loop, Parse, tt_text, `n
	{
		split := StrSplit( A_LoopField, "=", A_Space )			// Empty Area Tooltip
		if( split[1] == "Value" ){
			return  split[2]
		}
		
		split := StrSplit( A_LoopField, ",", A_Space )			// Line Tooltip
		split := StrSplit( split[2], ":", " `r`n" )				// Remove space and CR LF before/after number
		if( split[1] == "Value" ){
			return  split[2]
		}
	}

	return ""
}
