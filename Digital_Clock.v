/**
Student Name: Michael Sandrin
Student Number: 217144692
Assignment: Final Project
Course: EECS 3021
Instructor: Prof. Allison
Date of Completion: Sunday, December 5th, 2021
*/

module Digital_Clock(clock, button1, button2, switches, timeZone, LEDArray, audioOut, dOnesHours, dTensHours, dOnesMins, dTensMins, dMeridiem, dTimeZone);

	 //Clock: System Clock from the DE-10 Lite Board (50 Mhz)
    input clock;  
	 
	 //Buttons: Located on DE-10 Lite Board as the input keys
	 // (Button 1 = Key 0 on Board, Button 2 = Key 1 on Board)
    input button1, button2;
	 
	 /**Switches 6-0
	 ---------------------------------------------------------------------------------------------------------------------------
	 input [6:0] switches:
	 
	 
	 Switch 0: Pauses the Clock and allows time change (Seconds, Minutes and Hours)
	 Switch 1: Changes from 24 Hour Time to 12 Hour Meridiem Time & Seconds Removal
	 Switch 2: Stopwatch App
	 Switch 3: Alarm App
	 Switch 4: Adjust Seconds
	 Switch 5: Adjust Minutes
	 Switch 6: Adjust Hours
	 
	 
	 input [3:0] timeZone:
	 
	 
	 Switch 7: Used for Switching Time Zones (000:  UTC   0:00  |001:  NST  -3:30  )
	 Switch 8: Used for Switching Time Zones (010:  AST  -4:00  |011:  EST  -5:00  )
	 Switch 9: Used for Switching Time Zones (100:  CST  -6:00  |101:  MST  -7:00  )
														  (110:  PST  -8:00  |111:  YST  -9:00  )
	 ---------------------------------------------------------------------------------------------------------------------------
	*/
	
	 input [6:0] switches;
	 input [2:0] timeZone;
	 
	
	 
	//Internal variables

	/**Time Zone Values 
	
	PrevTZ: Saves the Previous Time Zone from prior value selection
	
	ValueTZ: Saves the Value of the Time Zone chose by the user using the Switches 7-9
	
	ChangeTZ: Finds the Difference between Time Zones chosen and the previous Time Zone
	
	*/
	
	 reg [5:0] prevTZ;
	 reg [5:0] valueTZ;
	 reg changeTZ;
	 
	 
	 
	 
	 /**
	 
	 LEDArray: Saves the values of the ON and OFF states of the LED Array (located above the 10 switches) in a 10 bit register 
	 and outputs the values using the LED's
	 
	 audioPlay: A register value that controls when audio plays on the speaker (ON state plays noise, OFF does not play noise)
	 
	 audioOut: The output signal to the speaker (sent as a alternating signal from music module) (Arduino_IO11)
	 
	 */
	 
	 output reg [9:0] LEDArray;
	 reg audioPlay;
	 output audioOut;
	 
	 
	 
	 
	 /**
	 
	 seconds: A register that saves the current value of seconds 
	 
	 minutes: A register that saves the current value of minutes 
	 
	 hours: A register that saves the current value of hours
	 
	 displayHours: A register that saves the modified values of hours which is displayed to the respective seven-segment displays
	 
	 displayMinutes: A register that saves the modified values of minutes which is displayed to the respective seven-segment displays
	 
	 displaySeconds: A register that saves the modified values of seconds which is displayed to the respective seven-segment displays
	 
	 reset: A register value that retains a signal to reset the clock, setting the values of the seconds, minutes and hours to 00:00:00 UTC
			  (Controlled by pressing both buttons together)
	 
	 */
	 
    reg [5:0] seconds;
    reg [5:0] minutes;
    reg [5:0] hours; 
	 reg [5:0] displayHours;
	 reg [5:0] displayMinutes;
	 reg [5:0] displaySeconds;
	 reg reset;

	 
	 
	 
	 //Timer Reg
	 
	 /**
	 
	 timerSeconds: A register that saves the starting seconds set by the user for the timer
	 
	 timerMinutes: A register that saves the starting minutes by the user for the timer
	 
	 timerHours: A register that saves the starting hours set by the user for the timer
	 
	 timerComplete: A register in which the all values of the 4-bit register will be 1's if the timer is officially complete
	 
	 timerSet: A register where all valus of 3-bit register will be 1's if the timer is completely set by the user, starting the timer when unpaused
	 
	 */
	 
	 reg [5:0] timerSeconds;
	 reg [5:0] timerMinutes;
	 reg [5:0] timerHours;
	 reg [3:0] timerComplete;
	 reg [2:0] timerSet;
	 
	 
	 //Alarm Reg
	 
	 /**
	 
	 alarmSeconds: A register that saves value of the seconds of the user's set alarm time
	 
	 alarmMinutes: A register that saves value of the minutes of the user's set alarm time
	 
	 alarmHours: A register that saves value of the hours of the user's set alarm time
	 
	 alarmBlinker: A register value that counts up that allows the LED Array to blink when the alarm goes off
	 
	 alarmSet: A register value that becomes "3'b111" when the alarm values are officially set, resulting in the alarm ready when the time comes
	 
	 */
	 
	 reg [5:0] alarmSeconds;
	 reg [5:0] alarmMinutes;
	 reg [5:0] alarmHours;
	 reg [3:0] alarmBlinker;
	 reg [2:0] alarmSet;
	 
	 
	//Seven Segment Display Outputs

	/**

	dTensHours: Displays the Tens Place of the Hours Value, displayed on Hex 5
	
	dOnesHours: Displays the Ones Place of the Hours Value, displayed on Hex 4
	
	dTensMins: Displays the Tens Place of the Minutes Value, displayed on Hex 3
	
	dOnesMins: Displays the Ones Place of the Minutes Value, displayed on Hex 2
	
	dMeridiem: Displays the Tens Place of the Seconds Value or the Meridiem of the time, displayed on Hex 1
	
	dTimeZone: Displays the Ones Place of the Seconds Value or the Time Zone chosen by the user, displayed on Hex 0

	*/
	
	 output [6:0] dTensHours; 
    output [6:0] dOnesHours;
	 output [6:0] dTensMins; 
	 output [6:0] dOnesMins; 
	 output [6:0] dMeridiem; 
	 output [6:0] dTimeZone;
	 
	 
	 
	//Meridiem Register Array (2-bit Binary Value), sets either AM or PM
	
	 reg [1:0] meridiem;

	 
	 
	//Wire that connects the clock divider to the main digital clock module 
	 wire dividedClock;
	 
	 
	 
	 //Calls on Clock Divider Module:
	
	 /**
	 
	 Inputs: clock
	 
	 Outputs: dividedClock (wire)
	 
	 */
	 
	 ClockDivider oneSec(clock, dividedClock);
		
	
	 //Calls on Music Module:
	
	 /**
	 
	 Inputs: clock, audioPlay
	 
	 Outputs: audioOut
	 
	 */
		
	 music alarmSound(clock, audioPlay, audioOut);
	 
	 
	 
	 
	 //START OF TIMEZONE CHOICE -------------------------------
	 
				always @(timeZone) begin
				
						casex (timeZone)
						
							3'b000: valueTZ = 6'b000000; //UTC =  0:00 (Displayed as U)
							3'b001: valueTZ = 6'b000011; //NST = -3:30 (Displayed as N)
							3'b010: valueTZ = 6'b000100; //AST = -4:00 (Displayed as A)
							3'b011: valueTZ = 6'b000101; //EST = -5:00 (Displayed as E)
							3'b100: valueTZ = 6'b000110; //CST = -6:00 (Displayed as C)
							3'b101: valueTZ = 6'b000111; //MST = -7:00 (Displayed as S)
							3'b110: valueTZ = 6'b001000; //PST = -8:00 (Displayed as P)
							3'b111: valueTZ = 6'b001001; //YST = -9:00 (Displayed as Y)
							
							default: valueTZ = 6'b000000;
								
						endcase	
						
						
						//If the time zone is changed by the user, the value of changeTZ = 1
						if (valueTZ != prevTZ) begin
						
							changeTZ = 1'b1;
								
							prevTZ = valueTZ; 
						
						end
						
						//If the time zone is the same, the value of changeTZ = 1
						else begin
						
						changeTZ = 1'b0;
						
						end
						
	 	
				end
	 
			
	 
	 
	 //END OF TIME ZONE CHOICE --------------------------------
	 
	 
	 

	 
	 
	 
	 //START OF CLOCK RESET SYSTEM -------------------------------
	 
	 //Resets if both buttons are pressed
	 
	 always @ (switches[0]) begin
	 
		//If both buttons are pressed, the clock gets reset
		if (~button1 && ~button2) begin
	 
		reset <= 1'b1;
		
		end
		
		else begin
	 
		reset <= 1'b0;
	 
		end
	 
	 end
	 
	 //END OF CLOCK RESET SYSTEM --------------------------------
	 
	 
	 
	 
	 
	
	 
	 
	 
	 


	 	
	 
   //Execute the always blocks when the Clock or reset inputs are 
    //changing from 0 to 1(positive edge of the signal)
    always @(posedge(dividedClock)) begin
			
		//If switch 0 (SW0) is turned on, the values of time can be change by the user using the other switches
		if(switches[0]) begin
			
			//If switch 4 (SW4) is turned on, Seconds Increment is active
	 
			if (switches[4]) begin
	 
	 
				//If neither Switches 2 and 3 (SW2 & SW3) are turned on, the seconds value can be change for the regular clock
				if((~switches[2]) & (~switches[3])) begin
	 
					if (~button1) begin
	 
						if(seconds >=  6'b111011) begin
					
						seconds <= 6'b000000;
					
						end 
					
						else begin
	 
						seconds <= seconds + 6'b000001;
					
						end
						
					end
		
					else if (~button2) begin
	 
						if(seconds == 6'b000000) begin
					
						seconds <= 6'b111011;
						
						end 
					
						else begin
	 
						seconds <= seconds - 6'b000001;
					
						end
		
					end 
					
					displaySeconds = seconds;
					
				end
				
				
				
				
				
				
				
				
				
				
				//If Switch 2 (SW2) is turned on and Switch 3 (SW3) is turned off, the seconds value can be change for the Timer
				
				else if((switches[2]) & (~switches[3])) begin
	 
					if (~button1) begin
	 
						if(timerSeconds >=  6'b111011) begin
					
						timerSeconds <= 6'b000000;
					
						end 
					
						else begin
	 
						timerSeconds <= timerSeconds + 6'b000001;
					
						end
						
					end
		
					else if (~button2) begin
	 
						if(timerSeconds == 6'b000000) begin
					
						timerSeconds <= 6'b111011;
						
						end 
					
						else begin
	 
						timerSeconds <= timerSeconds - 6'b000001;
					
						end
		
					end 
	 
					timerSet[0] <= 1'b1;
	 
					displaySeconds = timerSeconds;
					
				end
				
				
				
				
				
				
				//If Switch 3 (SW3) is turned on and Switch 2 (SW2) is turned off, the seconds value can be change for the Alarm
				
				if((~switches[2]) & (switches[3])) begin
	 
					if (~button1) begin
	 
						if(alarmSeconds >=  6'b111011) begin
					
						alarmSeconds <= 6'b000000;
					
						end 
					
						else begin
	 
						alarmSeconds <= alarmSeconds + 6'b000001;
					
						end
						
					end
		
					else if (~button2) begin
	 
						if(alarmSeconds == 6'b000000) begin
					
						alarmSeconds <= 6'b111011;
						
						end 
					
						else begin
	 
						alarmSeconds <= alarmSeconds - 6'b000001;
					
						end
		
					end 
	 
					alarmSet[0] <= 1'b1;
	 
					displaySeconds = alarmSeconds;
					
				end
				
			end
				
				
				
				
	 
	 

		
	

			//If switch 5 (SW5) is turned on, Minutes Increment is active
	 
			if (switches[5]) begin
		
		
				//If neither Switches 2 and 3 (SW2 & SW3) are turned on, the Minutesv value can be change for the regular clock
				if((~switches[2]) & (~switches[3])) begin
		
					if (~button1) begin
	 
						if(minutes >= 6'b111011) begin
					
						minutes <= 6'b000000;
					
						end
				
						else begin
	 
						minutes <= minutes + 6'b000001;
					
						end
		
					end 
	 
					else if (~button2) begin
	 
						if(minutes == 6'b000000) begin
					
						minutes <= 6'b111011;
					
						end 
					
						else begin
	 
						minutes <= minutes - 6'b000001;
					
						end
						
					end 
	 
					displayMinutes = minutes;
				
					
				
				end
				
				
				
				
				
				
				
				//If Switch 2 (SW2) is turned on and Switch 3 (SW3) is turned off, the minutes value can be change for the Timer
				
				else if((switches[2]) & (~switches[3])) begin
	 
					if (~button1) begin
	 
						if(timerMinutes >= 6'b111011) begin
					
						timerMinutes <= 6'b000000;
					
						end
				
						else begin
	 
						timerMinutes <= timerMinutes + 6'b000001;
					
						end
		
					end 
	 
					else if (~button2) begin
	 
						if(timerMinutes == 6'b000000) begin
					
						timerMinutes <= 6'b111011;
					
						end 
					
						else begin
	 
						timerMinutes <= timerMinutes - 6'b000001;
					
						end
						
					end 
					
					timerSet[1] <= 1'b1;
	 
					displayMinutes = timerMinutes;
	 
				end
	 
	 
				
				//If Switch 3 (SW3) is turned on and Switch 2 (SW2) is turned off, the minutes value can be change for the Alarm
	 
						if((~switches[2]) & (switches[3])) begin
	 
							if (~button1) begin
	 
						if(alarmMinutes >= 6'b111011) begin
					
						alarmMinutes <= 6'b000000;
					
						end
				
						else begin
	 
						alarmMinutes <= alarmMinutes + 6'b000001;
					
						end
		
					end 
	 
					else if (~button2) begin
	 
						if(alarmMinutes == 6'b000000) begin
					
						alarmMinutes <= 6'b111011;
					
						end 
					
						else begin
	 
						alarmMinutes <= alarmMinutes - 6'b000001;
					
						end
						
					end 
					
					alarmSet[1] <= 1'b1;
	 
					displayMinutes = alarmMinutes;
	 
				end
				
			end
			
			
			
			
			
	 
			//If switch 5 (SW5) is turned on, Hours Increment is active
	 
			if (switches[6]) begin
		
		
				//If neither Switches 2 and 3 (SW2 & SW3) are turned on, the hours value can be change for the regular clock
				if((~switches[2]) & (~switches[3])) begin
		
					if (~button1) begin
				
						if(hours >=  6'b010111) begin
					
						hours <= 6'b000000;
					
						end 
					
						else begin
	 
						hours <= hours + 6'b000001;
					
						end
		
					end 
	 
					else if (~button2) begin
	 
						if(hours == 6'b000000) begin
					
						hours <= 6'b010111;
					
						end 
					
						else begin
	 
						hours <= hours - 6'b000001;
					
						end
						
					end 
		
					displayHours = hours;
	
				end
				
				
				
				//If Switch 2 (SW2) is turned on and Switch 3 (SW3) is turned off, the hours value can be change for the Timer
				
				if((switches[2]) & (~switches[3])) begin
		
					if (~button1) begin
				
						if(timerHours >=  6'b010111) begin
					
						timerHours <= 6'b000000;
					
						end 
					
						else begin
	 
						timerHours <= timerHours + 6'b000001;
					
						end
		
					end 
	 
					else if (~button2) begin
	 
						if(timerHours == 6'b000000) begin
					
						timerHours <= 6'b010111;
					
						end 
					
						else begin
	 
						timerHours <= timerHours - 6'b000001;
					
						end
						
					end 
		
					timerSet[2] <= 1'b1;
			
					displayHours = timerHours;
					
				end
				
				
				
				//If Switch 3 (SW3) is turned on and Switch 2 (SW2) is turned off, the hours value can be change for the Alarm
				
				if((~switches[2]) & (switches[3])) begin
		
					if (~button1) begin
				
						if(alarmHours >=  6'b010111) begin
					
						alarmHours <= 6'b000000;
					
						end 
					
						else begin
	 
						alarmHours <= alarmHours + 6'b000001;
					
						end
		
					end 
	 
					else if (~button2) begin
	 
						if(alarmHours == 6'b000000) begin
					
						alarmHours <= 6'b010111;
					
						end 
					
						else begin
	 
						alarmHours <= alarmHours - 6'b000001;
					
						end
						
					end 
					
					alarmSet[2] <= 1'b1;
		
					displayHours = alarmHours;
					
				end
				
				
		
			end
		
		end
		
		
		
		
		
		//If Switch 0 (SW0) is turned off and Switch 3 (SW3) is turned on, the alarm set by the user will be active
		if ((~switches[0]) & (switches[3])) begin
		  
		  //If the alarm is complete or the alarm has not been turned off by the user, the following will occur
		  if(((alarmSet == 3'b111)) & ((alarmSeconds == seconds) & (alarmMinutes == minutes) & (alarmHours == hours)) | (alarmBlinker != 4'b0000)) begin
		
						//Turns on speaker
						audioPlay <= 1'b1;
						
				//Blinks the LED Array at the the rate of every 2 seconds		
				if(dividedClock == 1'b1) begin
						alarmBlinker <= alarmBlinker + 4'b0001;
						 
							//If both buttons are pressed by the user, the alarm sound and LED Array will stop
							if(~button1 | ~button2) begin
							alarmBlinker <= 4'b1111;
							end

						   //Resets the flashing to continuous blink until turned off
							if(alarmBlinker == 4'b1101) begin
							alarmBlinker <= 4'b0000;
							end
						 
						   //If reset, the speaker and LED Values stop
							else if(alarmBlinker == 4'b1111) begin
							alarmBlinker <= 4'b0000;
							audioPlay <= 1'b0;
							end
						
							//Turns off LED Array
							else if(alarmBlinker[0] == 1'b1) begin
							LEDArray <= 10'b0000000000;
							end
						
							//Turns on LED Array
							else begin
							LEDArray <= 10'b1111111111;
							end
							
							
							
				end
				
			end
		  
	 end
	 
	 
	 
	 
	 //If Switch 0 (SW0) is turned off and Switch 2 (SW2) is turned on, the timer set by the user will be active
	if ((~switches[0]) & (switches[2])) begin
		
	 //If the timer is set by the user, the timer will start when unpaused	
	if(timerSet == 3'b111) begin
	
		//If the timer is not complete, the timer will continue with the following:
		if(timerComplete == 4'b0000) begin
	 
	   //If the Clock sends a signal every second and it is the positive edge
		if(dividedClock == 1'b1) begin
		
			//Seconds subtracts by 1 second
			timerSeconds <= timerSeconds - 6'b000001;
			
			//if the value of seconds reaches 0, the following occurs:
			if(timerSeconds == 6'b000000) begin
			
				//If the timer minutes are still greater than 0, the seconds are reset to 59, and the minutes are subtracted by 1
				if(timerMinutes > 6'b000000) begin
				timerSeconds <= 6'b111011;
				timerMinutes <= timerMinutes - 6'b000001;
				end
				
				//If the timer hours are still greater than 0, the seconds and minutes are reset to 59, and the hours are subtracted by 1
				else begin
					if(timerHours > 6'b000000)begin
						timerMinutes <= 6'b111011;
						timerSeconds <= 6'b111011;
						timerHours <= timerHours - 6'b000001;
					end
					
					//Else, the timer is complete
					else begin
							timerComplete <= timerComplete + 4'b0001;
							
					end
				end
			end 
			
		end

		//Sets the displayed values on the clock to be the values from the timer for the user to display
		
		
		displaySeconds = timerSeconds;
		displayMinutes = timerMinutes;
		displayHours = timerHours;
		
	end
	
	
		
		//When complete, play the same speaker noise as the alarm
		else begin
				audioPlay <= 1'b1;
	 
						//If both buttons are pressed by the user, the alarm sound and LED Array will stop
						if(~button1 | ~button2) begin
							timerComplete <= 4'b1111;
						end
						
						//Resets the flashing to continuous blink until turned off
						if(timerComplete == 4'b1101) begin
							timerComplete <= 4'b0000;
							end
						
						//If reset, the speaker and LED Values stop
						else if(timerComplete == 4'b1111) begin
							timerComplete <= 4'b0000;
							audioPlay <= 1'b0;
							timerSet <= 3'b000;
							end
						
							//Turns off LED Array
							else if(timerComplete[0] == 1'b1) begin
							LEDArray <= 10'b0000000000;
							end
						
							//Turns on LED Array
							else begin
							LEDArray <= 10'b1111111111;
							end
	 
	 
				//Sets the displayed values on the clock to be the values from the timer for the user to display
				displaySeconds = timerSeconds;
				displayMinutes = timerMinutes;
				displayHours = timerHours;
	 
			end
	 
		end 
	 
	 end 
	 
	 //If Switch 0 (SW0) is turned off, the clock counts and is active. When SWitch 0 is turned on, the clock is paused
	 if(~switches[0]) begin
	 
		  //When both buttons are pressed, the clock is reset when the values are set to 0
        if(reset == 1'b1) begin 
            seconds <= 6'b000000;
            minutes <= 6'b000000;
            hours <= 6'b000000;  
		  end
		  
		  //If the Clock sends a signal every second and it is the positive edge
        else if(dividedClock == 1'b1) begin 
		  
				//Every elapsed second increases the seconds value by 1
            seconds <= seconds + 6'b000001;
				
				//If the seconds value is 59, the seconds value is reset to 0, and the minutes value increase by 1
            if(seconds >= 6'b111011) begin 
                seconds <= 6'b000000;  
                minutes <= minutes + 6'b000001; 
					 
					 //If the minutes value is 59, the minutes value is reset to 0, and the hours value increase by 1
                if(minutes >= 6'b111011) begin 
                    minutes <= 6'b000000;  
                    hours <= hours + 6'b000001; 
						  
						 //If the hours value is 24, the value of hours is reset to 0
                   if(hours >=  6'b011000) begin  
                        hours <= 6'b000000; 
                    end 
						  
                end
            end 
				

			end
		  
		  
		  //If Switch 2 (SW2) is turned off, meaning the timer is not enabled, the clock values will be displayed
		  if(~switches[2]) begin
		  
		  displayMinutes = minutes;
		  displaySeconds = seconds;
		  displayHours = hours;
		  
			end
		
		  
		  //If the Time Zone is changed, display hours is set to zero
		  if(changeTZ) begin
		  
		  displayHours = 6'b000000;
		  
		  end
		  
		  
		  //Checks the value of time zone and sets the values of display hours and display minutes to adjust to the time zone values
		  else begin
		  
		  
					if(hours < valueTZ) begin
						
						displayHours = 6'b011000 - (valueTZ - hours);
						
						end 
						
					else begin
						
						displayHours = hours - valueTZ;
						
					end
					
					
					
					if(valueTZ == 6'b000011) begin
		
						if(minutes > 6'b011101) begin
						
							displayMinutes = minutes - 6'b011110;
							
							
							if(displayMinutes == 6'b000000) begin
							
								displayHours = displayHours + 6'b000001;
								
							end
							
							
							
						end
						
						else if (minutes < 6'b011110) begin
						
						if(displayMinutes == 6'b111011) begin
							
								displayHours = displayHours + 6'b000001;
								
							end
						
						displayMinutes = displayMinutes + 6'b011110;
						
							
						
						end
						
						
					displayHours = displayHours - 6'b000001;
	
					end
					
					
				
					
					if(displayHours >= 6'b011000) begin
					
					displayHours = displayHours - 6'b011000;
					
					end
			
			  end
			  
			
			end
			
			
			
			//Changes Meridiem
	 
	 
	   if (displayHours >= 6'b001100) begin
		
		meridiem <= 2'b10;
		
		end
		
		else begin
		
		meridiem <= 2'b01;
		
		end
				
	end  
	
	
	
	
		//Calls on meridiemSevenSeg Module:
	
		/**
	 
		Inputs: switches[1], displaySeconds, meridiem
	 
		Outputs: dMeridiem
	 
		When Switch 1 (SW1) is turned on, the tens places of seconds are not displayed and the meridiem is displayed, setting the value to 12-hour time
	 
		*/
	 
		meridiemSevenSeg meridiemDisplay(switches[1], displaySeconds, meridiem, dMeridiem);

	
	
		//Calls on timeZoneSevenSeg Module:
	
		/**
	 
		Inputs: switches[1], displaySeconds, timeZone
	 
		Outputs: dTimeZone
	 
		When Switch 1 (SW1) is turned on, the ones place of seconds are not displayed and the user's chosen time zone is displayed, setting the value to 12-hour time
	 
		*/
	 
		timeZoneSevenSeg timeZoneDisplay (switches[1], displaySeconds, timeZone, dTimeZone);

	
	
		//Calls on onesSevenSeg Module:
	
		/**
	 
		Inputs: switches[1], displayMinutes
		
		Outputs: dOnesMins
	 
		*/
		
		onesSevenSeg minOnesDisplay(0,displayMinutes, dOnesMins);
		
	
	
		//Calls on onesSevenSeg Module:
	
		/**
	 
		Inputs: switches[1], displayMinutes
	 
		Outputs: dOnesMins
	 
		*/
		
		tensSevenSeg minTensDisplay(0,displayMinutes, dTensMins);
		
	
	
		//Calls on onesSevenSeg Module:
	
		/**
	 
		Inputs: switches[1], displayHours
		
		Outputs: dOnesHours
	 
		When Switch 1 (SW1) is turned on, the Hours are set to 12-hour time rather than 24-hour time when Switch 1 is off
	 
		*/
	 
		onesSevenSeg hourOnesDisplay(switches[1],displayHours, dOnesHours);
		
		
		
		//Calls on tensSevenSeg Module:
	
		/**
	 
		Inputs: switches[1], displayHours
		
		Outputs: dTensHours
	 
		When Switch 1 (SW1) is turned on, the Hours are set to 12-hour time rather than 24-hour time when Switch 1 is off
	 
		*/
		
		tensSevenSeg hourTensDisplay(switches[1],displayHours, dTensHours);
	 
endmodule







//The Following Modules are used for the Seven Segment Displays

//Module to Set Values for Ones Place Seven Segment Display (Displays Integer)
module onesSevenSeg (choice, x, d);

input choice;


//Binary value in Array Form
input [5:0] x;


//Output as correct elements on the Seven Segment Displays
output [6:0] d;


assign d[0] = (((~choice) & ((~x[5] & ~x[4] & ~x[3] & ~x[2] & ~x[1] & x[0]) | (~x[5] & ~x[4] & ~x[3] & x[2] & ~x[1] & ~x[0]) | (~x[5] & ~x[4] & x[3] & ~x[2] & x[1] & x[0]) | (~x[5] & ~x[4] & x[3] & x[2] & x[1] & ~x[0]) | (~x[5] & x[4] & ~x[3] & x[2] & ~x[1] & x[0]) | (~x[5] & x[4] & x[3] & ~x[2] & ~x[1] & ~x[0]) | (~x[5] & x[4] & x[3] & x[2] & x[1] & x[0]) | (x[5] & ~x[4] & ~x[3] & ~x[2] & x[1] & ~x[0]) | (x[5] & ~x[4] & x[3] & ~x[2] & ~x[1] & x[0]) | (x[5] & ~x[4] & x[3] & x[2] & ~x[1] & ~x[0]) | (x[5] & x[4] & ~x[3] & ~x[2] & x[1] & x[0]) | (x[5] & x[4] & ~x[3] & x[2] & x[1] & ~x[0]) | (x[5] & x[4] & x[3] & x[2] & ~x[1] & x[0]))) | ((choice) & ((~x[4] & ~x[3] & ~x[2] & ~x[1] & x[0]) | (~x[4] & ~x[3] & x[2] & ~x[1] & ~x[0]) | (x[3] & ~x[2] & x[1] & x[0]) | (x[3] & x[2] & ~x[1] & x[0]) | (x[4] & ~x[2] & ~x[1] & ~x[0]) | (x[4] & x[2] & x[1] & x[0]) | (x[4] & x[3]) | (x[5]))));

assign d[1] = (((~choice) & ((~x[5] & ~x[4] & ~x[3] & x[2] & ~x[1] & x[0]) | (~x[5] & ~x[4] & ~x[3] & x[2] & x[1] & ~x[0]) | (~x[5] & ~x[4] & x[3] & x[2] & x[1] & x[0]) | (~x[5] & x[4] & ~x[3] & ~x[2] & ~x[1] & ~x[0]) | (~x[5] & x[4] & x[3] & ~x[2] & ~x[1] & x[0]) | (~x[5] & x[4] & x[3] & ~x[2] & x[1] & ~x[0]) | (x[5] & ~x[4] & ~x[3] & ~x[2] & x[1] & x[0]) | (x[5] & ~x[4] & ~x[3] & x[2] & ~x[1] & ~x[0]) | (x[5] & ~x[4] & x[3] & x[2] & ~x[1] & x[0]) | (x[5] & ~x[4] & x[3] & x[2] & x[1] & ~x[0]) | (x[5] & x[4] & ~x[3] & x[2] & x[1] & x[0]) | (x[5] & x[4] & x[3] & ~x[2] & ~x[1] & ~x[0]))) | ((choice) & ((~x[4] & ~x[3] & x[2] & ~x[1] & x[0]) | (~x[4] & ~x[3] & x[2] & x[1] & ~x[0]) | (x[4] & ~x[2] & ~x[1] & x[0]) | (x[4] & ~x[2] & x[1] & ~x[0]) | (x[4] & x[3]) | (x[5]))));

assign d[2] = (((~choice) & ((~x[5] & ~x[4] & ~x[3] & ~x[2] & x[1] & ~x[0]) | (~x[5] & ~x[4] & x[3] & x[2] & ~x[1] & ~x[0]) | (~x[5] & x[4] & ~x[3] & x[2] & x[1] & ~x[0]) | (x[5] & ~x[4] & ~x[3] & ~x[2] & ~x[1] & ~x[0]) | (x[5] & ~x[4] & x[3] & ~x[2] & x[1] & ~x[0]) | (x[5] & x[4] & ~x[3] & x[2] & ~x[1] & ~x[0]) | (x[5] & x[4] & x[3] & x[2] & x[1] & ~x[0]))) | ((choice) & ((~x[4] & ~x[3] & ~x[2] & ~x[0]) | (x[3] & x[2] & ~x[0]) | (x[4] & x[3]) | (x[5]))));

assign d[3] = (((~choice) & ((~x[5] & ~x[4] & ~x[3] & x[2] & ~x[1] & ~x[0]) | (~x[4] & ~x[3] & x[2] & x[1] & x[0]) | (~x[5] & ~x[4] & x[3] & x[2] & x[1] & ~x[0]) | (~x[5] & x[4] & x[3] & ~x[2] & ~x[1] & ~x[0]) | (x[5] & ~x[4] & ~x[3] & ~x[2] & x[1] & ~x[0]) | (x[5] & ~x[4] & ~x[3] & x[2] & x[0]) | (x[5] & ~x[4] & x[3] & x[2] & ~x[1] & ~x[0]) | (x[5] & ~x[4] & x[2] & x[1] & x[0]) | (x[5] & x[4] & ~x[3] & x[2] & x[1] & ~x[0]) | (~x[5] & ~x[4] & ~x[2] & ~x[1] & x[0]) | (~x[5] & ~x[4] & x[3] & ~x[2] & x[0]) | (~x[5] & x[4] & ~x[3] & ~x[1] & x[0]) | (x[4] & ~x[2] & x[1] & x[0]) | (~x[5] & x[4] & x[3] & x[2] & x[0]) | (~x[4] & x[3] & ~x[2] & ~x[1] & x[0]) | (x[4] & ~x[3] & ~x[2] & x[0]) | (x[5] & x[4] & x[3] & ~x[1] & x[0]))) | ((choice) & ((~x[4] & ~x[2] & ~x[1] & x[0]) | (~x[4] & ~x[3] & x[2] & ~x[1] & ~x[0]) | (~x[3] & x[2] & x[1] & x[0]) | (x[3] & ~x[2] & x[0]) | (x[3] & ~x[1] & x[0]) | (x[4] & ~x[2] & ~x[1] & ~x[0]) | (x[4] & x[1] & x[0]) | (x[4] & x[2] & x[0]) | (x[4] & x[3]) | (x[5]))));

assign d[4] = (((~choice) & ((x[0]) | (~x[5] & ~x[4] & ~x[3] & x[2] & ~x[1]) | (~x[5] & ~x[4] & x[3] & x[2] & x[1]) | (~x[5] & x[4] & x[3] & ~x[2] & ~x[1]) | (x[5] & ~x[4] & ~x[3] & ~x[2] & x[1]) | (x[5] & ~x[4] & x[3] & x[2] & ~x[1]) | (x[5] & x[4] & ~x[3] & x[2] & x[1]))) | ((choice) & ((x[0]) | (~x[4] & ~x[3] & x[2] & ~x[1]) | (x[4] & ~x[2] & ~x[1]) | (x[4] & x[3]) | (x[5]))));

assign d[5] = (((~choice) & ((~x[5] & ~x[4] & ~x[3] & ~x[2] & x[1]) | (~x[5] & ~x[4] & x[3] & x[2] & ~x[1]) | (~x[5] & x[4] & ~x[3] & x[2] & x[1]) | (x[5] & ~x[4] & ~x[3] & ~x[2] & ~x[1]) | (x[5] & ~x[4] & x[3] & ~x[2] & x[1]) | (x[5] & x[4] & ~x[3] & ~x[2] & x[1] & x[0]) | (x[5] & x[4] & ~x[3] & x[2] & ~x[1]) | (x[5] & x[4] & x[3] & x[2] & x[1]) | (~x[5] & ~x[4] & ~x[3] & ~x[2] & x[0]) | (~x[5] & ~x[4] & ~x[3] & x[1] & x[0]) | (~x[5] & ~x[4] & ~x[2] & x[1] & x[0]) | (~x[5] & x[4] & ~x[3] & ~x[1] & x[0]) | (~x[5] & x[4] & x[3] & x[1] & x[0]) | (x[5] & ~x[4] & ~x[3] & ~x[1] & x[0]) | (x[5] & ~x[4] & ~x[2] & ~x[1] & x[0]) | (x[5] & ~x[4] & x[3] & x[1] & x[0]) | (x[5] & x[4] & x[3] & ~x[1] & x[0]))) | ((choice) & ((~x[4] & ~x[3] & ~x[2]) | (x[1] & x[0]) | (x[3] & x[2]) | (x[4] & x[3]) | (x[5]))));

assign d[6] = (((~choice) & ((~x[5] & ~x[4] & ~x[3] & ~x[2] & ~x[1]) | (~x[5] & ~x[4] & ~x[3] & x[2] & x[1] & x[0]) | (~x[5] & ~x[4] & x[3] & ~x[2] & x[1]) | (~x[5] & x[4] & ~x[3] & x[2] & ~x[1]) | (~x[5] & x[4] & x[3] & x[2] & x[1]) | (x[5] & ~x[4] & ~x[3] & x[2] & ~x[1] & x[0]) | (x[5] & ~x[4] & x[3] & ~x[2] & ~x[1]) | (x[5] & ~x[4] & x[3] & x[2] & x[1] & x[0]) | (x[5] & x[4] & ~x[3] & ~x[2] & x[1]) | (x[5] & x[4] & x[3] & x[2] & ~x[1]) | (~x[5] & ~x[3] & ~x[2] & ~x[1] & x[0]) | (~x[5] & x[3] & ~x[2] & x[1] & x[0]) | (x[5] & x[3] & ~x[2] & ~x[1] & x[0]))) | ((choice) & ( (~x[4] & ~x[3] & ~x[2] & ~x[1] & x[0]) | (~x[3] & x[2] & x[1] & x[0]) | (x[3] & ~x[2] & x[1]) | (x[3] & x[2] & ~x[1] & x[0]) | (x[4] & x[1] & x[0]) | (x[4] & x[2] & x[1]) | (x[4] & x[3]) | (x[5]))));

endmodule



//Module to Set Values for Tens Place Seven Segment Display (Displays Integer)
module tensSevenSeg (choice, x, d);


input choice;

//Binary value in Array Form
input [5:0] x;


//Output as correct elements on the Seven Segment Displays
output [6:0] d;

assign d[0] = (((~choice) & ((~x[4] & x[3] & x[1]) | (~x[4] & x[3] & x[2]) | (~x[5] & x[4] & ~x[3] & ~x[2]) | (x[5] & ~x[4] & x[3]) | (x[4] & ~x[3] & ~x[2] & ~x[1]))) | (choice));

assign d[1] = (((~choice) & ((x[5] & x[4] & x[1]) | (x[5] & x[4] & x[2]) | (x[5] & x[4] & x[3]))) | ((choice) & ((x[3] & ~x[2] & ~x[1]) | (x[5]) | (~x[1] & x[0]) | (~x[4] & ~x[3] & x[1]) | (~x[4] & ~x[3] & x[2]) | (x[3] & x[2] & x[1]) | (x[4] & ~x[2]) | (x[4] & ~x[1]))));

assign d[2] = (((~choice) & ((~x[5] & x[4] & ~x[3] & x[2]) | (~x[5] & x[4] & x[3] & ~x[2]) | (~x[5] & x[4] & x[2] & ~x[1]))) | ((choice) & ((x[3] & ~x[2] & ~x[1]) | (x[5]) | (~x[1] & x[0]) | (~x[4] & ~x[3] & x[1]) | (~x[4] & ~x[3] & x[2]) | (x[3] & x[2] & x[1]) | (x[4] & ~x[2]) | (x[4] & ~x[1]))));

assign d[3] = (((~choice) & ((~x[4] & x[3] & x[1]) | (~x[4] & x[3] & x[2]) | (~x[5] & x[4] & ~x[3] & ~x[2]) | (x[5] & ~x[4] & x[3]) | (x[4] & ~x[3] & ~x[2] & ~x[1]))) | (choice));

assign d[4] = (((~choice) & ((~x[4] & x[3] & x[1]) | (~x[4] & x[3] & x[2]) | (x[4] & ~x[3] & ~x[2]) | (~x[5] & x[3] & x[2] & x[1]) | (x[5] & ~x[3]) | (x[5] & ~x[2]))) | (choice));

assign d[5] = (((~choice) & ((~x[5] & x[3] & x[1]) | (~x[5] & x[3] & x[2]) | (~x[5] & x[4]) | (x[5] & ~x[4] & ~x[3]))) | (choice));

assign d[6] = (((~choice) & ((~x[5] & ~x[4]) | (~x[5] & ~x[3] & ~x[2]))) | (choice));

endmodule


//Module to Set Values for Set Meridiem Seven Segment Display (Displays Integer)
module meridiemSevenSeg (choice, x, xx, d);

//Binary value in Array Form 
input choice;

input [5:0] x;

input [1:0] xx;


//Output as correct elements on the Seven Segment Displays
output [6:0] d;






assign d[0] = (((choice) & ((~xx[1] & ~xx[0])|(xx[1] & xx[0]))) | ((~choice) & ((~x[4] & x[3] & x[1]) | (~x[4] & x[3] & x[2]) | (~x[5] & x[4] & ~x[3] & ~x[2]) | (x[5] & ~x[4] & x[3]) | (x[4] & ~x[3] & ~x[2] & ~x[1]))));

assign d[1] = (((choice) & ((~xx[1] & ~xx[0])|(xx[1] & xx[0]))) | ((~choice) & ((x[5] & x[4] & x[1]) | (x[5] & x[4] & x[2]) | (x[5] & x[4] & x[3]))));

assign d[2] = (((choice) & ((~xx[0])|(xx[1] & xx[0]))) | ((~choice) & ((~x[5] & x[4] & ~x[3] & x[2]) | (~x[5] & x[4] & x[3] & ~x[2]) | (~x[5] & x[4] & x[2] & ~x[1]))));

assign d[3] = (((choice) & 1) | ((~choice) & ((~x[4] & x[3] & x[1]) | (~x[4] & x[3] & x[2]) | (~x[5] & x[4] & ~x[3] & ~x[2]) | (x[5] & ~x[4] & x[3]) | (x[4] & ~x[3] & ~x[2] & ~x[1]))));

assign d[4] = (((choice) & ((~xx[1] & ~xx[0])|(xx[1] & xx[0]))) | ((~choice) & ((~x[4] & x[3] & x[1]) | (~x[4] & x[3] & x[2]) | (x[4] & ~x[3] & ~x[2]) | (~x[5] & x[3] & x[2] & x[1]) | (x[5] & ~x[3]) | (x[5] & ~x[2]))));

assign d[5] = (((choice) & ((~xx[1] & ~xx[0])|(xx[1] & xx[0]))) | ((~choice) & ((~x[5] & x[3] & x[1]) | (~x[5] & x[3] & x[2]) | (~x[5] & x[4]) | (x[5] & ~x[4] & ~x[3]))));

assign d[6] = (((choice) & ((~xx[1] & ~xx[0])|(xx[1] & xx[0]))) | ((~choice) & ((~x[5] & ~x[4]) | (~x[5] & ~x[3] & ~x[2]))));

endmodule




//Module to Set Values for Set Meridiem Seven Segment Display (Displays Integer)
module timeZoneSevenSeg (choice, x, xx, d);

//Binary value in Array Form
input choice;
input [5:0] x; 
input [2:0] xx;


//Output as correct elements on the Seven Segment Displays
output [6:0] d;




assign d[0] = (((choice) & ((~xx[2] & ~xx[1] & ~xx[0]) | (xx[2] & xx[1] & xx[0]))) | ((~choice) & ((~x[5] & ~x[4] & ~x[3] & ~x[2] & ~x[1] & x[0]) | (~x[5] & ~x[4] & ~x[3] & x[2] & ~x[1] & ~x[0]) | (~x[5] & ~x[4] & x[3] & ~x[2] & x[1] & x[0]) | (~x[5] & ~x[4] & x[3] & x[2] & x[1] & ~x[0]) | (~x[5] & x[4] & ~x[3] & x[2] & ~x[1] & x[0]) | (~x[5] & x[4] & x[3] & ~x[2] & ~x[1] & ~x[0]) | (~x[5] & x[4] & x[3] & x[2] & x[1] & x[0]) | (x[5] & ~x[4] & ~x[3] & ~x[2] & x[1] & ~x[0]) | (x[5] & ~x[4] & x[3] & ~x[2] & ~x[1] & x[0]) | (x[5] & ~x[4] & x[3] & x[2] & ~x[1] & ~x[0]) | (x[5] & x[4] & ~x[3] & ~x[2] & x[1] & x[0]) | (x[5] & x[4] & ~x[3] & x[2] & x[1] & ~x[0]) | (x[5] & x[4] & x[3] & x[2] & ~x[1] & x[0])))  );

assign d[1] = (((choice) & ((~xx[2] & xx[1] & xx[0]) | (xx[2] & ~xx[1])))  | ( (~choice) & ((~x[5] & ~x[4] & ~x[3] & x[2] & ~x[1] & x[0]) | (~x[5] & ~x[4] & ~x[3] & x[2] & x[1] & ~x[0]) | (~x[5] & ~x[4] & x[3] & x[2] & x[1] & x[0]) | (~x[5] & x[4] & ~x[3] & ~x[2] & ~x[1] & ~x[0]) | (~x[5] & x[4] & x[3] & ~x[2] & ~x[1] & x[0]) | (~x[5] & x[4] & x[3] & ~x[2] & x[1] & ~x[0]) | (x[5] & ~x[4] & ~x[3] & ~x[2] & x[1] & x[0]) | (x[5] & ~x[4] & ~x[3] & x[2] & ~x[1] & ~x[0]) | (x[5] & ~x[4] & x[3] & x[2] & ~x[1] & x[0]) | (x[5] & ~x[4] & x[3] & x[2] & x[1] & ~x[0]) | (x[5] & x[4] & ~x[3] & x[2] & x[1] & x[0]) | (x[5] & x[4] & x[3] & ~x[2] & ~x[1] & ~x[0])) )  );

assign d[2] = (((choice) & ((~xx[2] & xx[1] & xx[0]) | (xx[2] & ~xx[0])))  | ( (~choice) & ((~x[5] & ~x[4] & ~x[3] & ~x[2] & x[1] & ~x[0]) | (~x[5] & ~x[4] & x[3] & x[2] & ~x[1] & ~x[0]) | (~x[5] & x[4] & ~x[3] & x[2] & x[1] & ~x[0]) | (x[5] & ~x[4] & ~x[3] & ~x[2] & ~x[1] & ~x[0]) | (x[5] & ~x[4] & x[3] & ~x[2] & x[1] & ~x[0]) | (x[5] & x[4] & ~x[3] & x[2] & ~x[1] & ~x[0]) | (x[5] & x[4] & x[3] & x[2] & x[1] & ~x[0])) )  );

assign d[3] = (((choice) & ((~xx[2] & ~xx[1] & xx[0]) | (xx[1] & ~xx[0]))) |  ( (~choice) & ((~x[5] & ~x[4] & ~x[3] & x[2] & ~x[1] & ~x[0]) | (~x[4] & ~x[3] & x[2] & x[1] & x[0]) | (~x[5] & ~x[4] & x[3] & x[2] & x[1] & ~x[0]) | (~x[5] & x[4] & x[3] & ~x[2] & ~x[1] & ~x[0]) | (x[5] & ~x[4] & ~x[3] & ~x[2] & x[1] & ~x[0]) | (x[5] & ~x[4] & ~x[3] & x[2] & x[0]) | (x[5] & ~x[4] & x[3] & x[2] & ~x[1] & ~x[0]) | (x[5] & ~x[4] & x[2] & x[1] & x[0]) | (x[5] & x[4] & ~x[3] & x[2] & x[1] & ~x[0]) | (~x[5] & ~x[4] & ~x[2] & ~x[1] & x[0]) | (~x[5] & ~x[4] & x[3] & ~x[2] & x[0]) | (~x[5] & x[4] & ~x[3] & ~x[1] & x[0]) | (x[4] & ~x[2] & x[1] & x[0]) | (~x[5] & x[4] & x[3] & x[2] & x[0]) | (~x[4] & x[3] & ~x[2] & ~x[1] & x[0]) | (x[4] & ~x[3] & ~x[2] & x[0]) | (x[5] & x[4] & x[3] & ~x[1] & x[0])) )  );

assign d[4] = (((choice) & (xx[2] & xx[0])) |  ( (~choice) & ((x[0]) | (~x[5] & ~x[4] & ~x[3] & x[2] & ~x[1]) | (~x[5] & ~x[4] & x[3] & x[2] & x[1]) | (~x[5] & x[4] & x[3] & ~x[2] & ~x[1]) | (x[5] & ~x[4] & ~x[3] & ~x[2] & x[1]) | (x[5] & ~x[4] & x[3] & x[2] & ~x[1]) | (x[5] & x[4] & ~x[3] & x[2] & x[1])) )  );

assign d[5] = (((choice) & 0))  | ( (~choice) & ((~x[5] & ~x[4] & ~x[3] & ~x[2] & x[1]) | (~x[5] & ~x[4] & x[3] & x[2] & ~x[1]) | (~x[5] & x[4] & ~x[3] & x[2] & x[1]) | (x[5] & ~x[4] & ~x[3] & ~x[2] & ~x[1]) | (x[5] & ~x[4] & x[3] & ~x[2] & x[1]) | (x[5] & x[4] & ~x[3] & ~x[2] & x[1] & x[0]) | (x[5] & x[4] & ~x[3] & x[2] & ~x[1]) | (x[5] & x[4] & x[3] & x[2] & x[1]) | (~x[5] & ~x[4] & ~x[3] & ~x[2] & x[0]) | (~x[5] & ~x[4] & ~x[3] & x[1] & x[0]) | (~x[5] & ~x[4] & ~x[2] & x[1] & x[0]) | (~x[5] & x[4] & ~x[3] & ~x[1] & x[0]) | (~x[5] & x[4] & x[3] & x[1] & x[0]) | (x[5] & ~x[4] & ~x[3] & ~x[1] & x[0]) | (x[5] & ~x[4] & ~x[2] & ~x[1] & x[0]) | (x[5] & ~x[4] & x[3] & x[1] & x[0]) | (x[5] & x[4] & x[3] & ~x[1] & x[0])) )  ;

assign d[6] = (((choice) & ((~xx[2] & ~xx[1]) | (~xx[1] & ~xx[0]))) |  ( (~choice) & ((~x[5] & ~x[4] & ~x[3] & ~x[2] & ~x[1]) | (~x[5] & ~x[4] & ~x[3] & x[2] & x[1] & x[0]) | (~x[5] & ~x[4] & x[3] & ~x[2] & x[1]) | (~x[5] & x[4] & ~x[3] & x[2] & ~x[1]) | (~x[5] & x[4] & x[3] & x[2] & x[1]) | (x[5] & ~x[4] & ~x[3] & x[2] & ~x[1] & x[0]) | (x[5] & ~x[4] & x[3] & ~x[2] & ~x[1]) | (x[5] & ~x[4] & x[3] & x[2] & x[1] & x[0]) | (x[5] & x[4] & ~x[3] & ~x[2] & x[1]) | (x[5] & x[4] & x[3] & x[2] & ~x[1]) | (~x[5] & ~x[3] & ~x[2] & ~x[1] & x[0]) | (~x[5] & x[3] & ~x[2] & x[1] & x[0]) | (x[5] & x[3] & ~x[2] & ~x[1] & x[0])) )  );

endmodule





















module ClockDivider(cin,cout);

// Based on code from fpga4student.com
// cin is the input clock; if from the DE10-Lite,
// the input clock will be at 50 MHz
// The clock divider toggles cout every 25 million cycles of the input clock

input cin;
output reg cout;

reg[31:0] count; 
parameter D = 32'd25000000;

always @(posedge cin)
begin
   count <= count + 32'd1;
      if (count >= (D-1)) begin
         cout <= ~cout;
         count <= 32'd0;
      end
end


endmodule




module music(clk, play, speaker);

// Based on code from fpga4fun.com
// Slightly modified to play when told to
// clk is the input clock; if from the DE10-Lite,
// the input clock will be at 50 MHz
// The clock divider toggles cout every 25 million cycles of the input clock
// play is the input from the digital clock module that tells the music module to play music
// speaker is the output, where the signal is sent to

input clk;
input play;
output reg speaker;

//Parameter used for the values of the inputs
parameter clkdivider = 25000000/440/2;
reg [23:0] tone;
reg [14:0] counter;

always @(posedge clk) begin

   //If the module is told to play audio, the following occurs
	if(play) begin

		tone <= tone+1;
 
		if(counter==0) counter <= (tone[23] ? clkdivider-1 : clkdivider/2-1); else counter <= counter-1;

		if(counter==0) speaker <= ~speaker;

	end
	
end

endmodule




















