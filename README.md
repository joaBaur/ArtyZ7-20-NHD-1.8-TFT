# ArtyZ7-20-NHD-1.8-TFT
VHDL project for the ArtyZ7-20 to send partial HDMI to the NHD-1.8-128160EF TFT (ILI9163, 8 bit parallel)

This is a driver for a Newhaven 1.8" TFT display (http://www.newhavendisplay.com/tfts-18-tfts-c-1_589.html). It reads the HDMI IN video signals, extracts a 160x128 pixel area and sends this to the TFT display via the 8 bit parallel interface.

![TFT showing 160x128 area](/images/raspberry-desktop-160x128.jpg)

*A 160x128 area of the Raspberry Pi's desktop rendered on the TFT*

![TFT showing 320x256 area](/images/raspberry-desktop-320x256.jpg) 

*A 320x256 area (crudely) downscaled to the 160x128 TFT pixels*

The driver init code sets up the 8 bit parallel interface to the 18 bit per pixel color mode. So 8 bits for the red, green and blue pixel values are transferred, but only the highest 6 bits of each color is used by the display's driver.

A write cycle for transferring a single 8 bit value takes a minimum time of 66 ns according to the ILI9163 data sheet. To be on the safe side, the driver implements a write cycle period of 80 ns. Even with the 80 ns we can achieve a refresh rate of 160x128 pixels x 3 bytes (R+G+B) x 80 ns = 4.9152 milliseconds per frame, which is roughly 200 frames per second.

The VHDL project was developed and tested on the Diligent ArtyZ7-20 board, but should run on any FPGA board with a HDMI IN or DVI IN connector that is supported by the Vivado IDE.

### Software and IP versions

The project was created using the free Vivado Webpack Editor 2018.1 and the included Vivado IP:

* clk_wiz / Clocking Wizard v6.0
* blk_mem_gen / Block Memory Generator v8.4 (Rev. 1)

plus the free Diligent IP for Vivado from Github:

* dvi2rgb / DVI to RGB Video Decoder (Sink) v1.9 (Rev. 1)
* rgb2dvi / RGB to DVI Video Encoder (Source) v1.4 (Rev. 7)
* ila / Integrated Logic Analyzer v6.2 (Rev. 6) 

## Physical setup

**Part list:**

* Diligent Arty Z7-20 FPGA development board
* NHD-1.8-128160EF TFT display with ILI9163 driver IC
* Breakout-Board (at least 24 pins / 0.8mm pitch or 0.5mm pitch for the -F variants of the TFT)


### Connecting the NHD TFT to the Arty

* **Power** supplied via USB or REG to the Arty board
* **HDMI IN** connected to video source, max 1920x1080 @ 60 Hz (I used a Raspberry Pi for testing)
* **HDMI OUT (optional)** connected to external monitor, the video data from HDMI IN is passed through to HDMI OUT
* Connect the **TFT Pins** from the breakout to the **Arty's IO** (I used simple jumper wires) like this:  
```
          TFT   ARTY  
    ---------   ---------   
       GND  1   GND  
     IOVDD  2   3V3 (typical 2.8V, max 3.3V)    
       VDD  3   3V3      
       /CS  4   GND (= CS is always enabled)
      /RES  5   IO8     
       D/C  6   IO9   
       /WR  7   IO10   
       /RD  8   3V3 (the read function is not used)   
       DB0  9   IO0   
       DB1 10   IO1   
       DB2 11   IO2   
       DB3 12   IO3   
       DB4 13   IO4   
       DB5 14   IO5   
       DB6 15   IO6   
       DB7 16   IO7  
     LED-A 17   3V3  
    LED-K1 18   GND   
    LED-K2 19   GND 
     	GND 20   GND
     NC/YU 21   - 
     NC/XL 22   - 
     NC/YD 23   - 
     NC/XR 24   -    
```
![Afafruit Breakout with mounted TFT](/images/Adafruit_Breakout.jpg)

## Creating the Vivado project

1. Download and install the Vivado Webpack Edition  
https://xilinx.com/support/download.html

2. Download and install the Arty Z7-20 board files  
https://github.com/Digilent/vivado-boards

3. Download and unzip the Digilent Vivado IP library release "vivado-library-2016.4.zip"  
https://github.com/Digilent/vivado-library/releases  
To add the unzipped Diligent IP folder to the Vivado Editor's "IP Defaults" settings, go to the "Tools" menu in Vivado, choose "Settings" and then "IP Defaults" in the left column. Then press the "+" button and select the folder you unzipped the Diligent IP to, in my case **"C:\Diligent_Vivado_IP"**.

4. Download the files from the **"source"** folder of this repository onto your harddrive.  
I recommend using a short path name that does not contain spaces, in my case **"C:\NHD_18"**  

    C:\NHD_18\ArtyZ7_20Master.xdc  
    C:\NHD_18\create_project.tcl  
    C:\NHD_18\Driver_8bitParallel.vhd  
    C:\NHD_18\Main_wrapper.vhd  
    C:\NHD_18\Main.bd  
    C:\NHD_18\NHD_18_128160EF_Init.vhd  
    C:\NHD_18\NHD_18_128160EF.vhd  
    C:\NHD_18\VideoProcessing.vhd  

5. Create the project by running the included create_project.tcl script

* Open the **create_project.tcl** script with a text editor, locate line 158:   
`set_property "ip_repo_paths" "[file normalize "C:/Diligent_Vivado_IP"]" $obj`  
change `C:/Diligent_Vivado_IP` to the path where you unzipped your IP to in step (3), using forward slashes in the path name

* Start the Vivado 2018.1 Editor  
On the welcome page, you can see the tcl console at the bottom

* Type **"cd C:/NHD_18"** (adjust the path to where you put your source files on your harddisk in step (4) - again, using forward slashes instead of backslashes) into the tcl console prompt, then press return

* Type **"source ./create_project.tcl"** into the tcl console prompt and press return

The Vivado project "ArtyZ7-20-NHD-1.8" is generated and opened in the Vivado Editor.

![BLock design diagram of the created project](/images/vivado_block_design.png)

*The block design diagram of the ArtyZ7-20-NHD-1.8 project*

## Runtime options

The two switches SW0 and SW1 on the Arty board can be used to configure the display content:

***SW0 changes the resolution on the tft***  
when switched on, only every other pixel is written to the block ram, so an area of 640x320 pixels is (crudely) downscaled to th 240x320 tft size

***SW1 can be used for testing the driver functionality without an HDMI signal***  
when switched off, a full screen red-green-blue sequence is shown on the tft

## Offsetting the TFT display area

The 128x160 pixel area that is output to the TFT has its origin by default at the upper left corner (0/0) of the HDMI frame. If you want to move the area to some other location within the HDMI frame, you can change the values of the constants `h_start` and `v_start` in the VideoProcessing.vhd file at line numbers 42 and 46 respectively.

## Issue with the MADCTRL init parameter

I have an issue with the initialization sequence for the TFT in my test setup here - no matter what value I pass to the MADCTRL (Memory Access Control) register 36h, the orientation and mirroring of the image on the TFT does not change, nor does the RGB ordering. So I hardcoded a mirroring into the NHD_18_128160EF.vhd for the image to appear correctly oriented and not mirrored. No idea why the MADCTL does not do anything, other init commands are applied correctly.
