This is a release of the VRKit's ImageScripts package, that can be used to
build Virtual Rotuers (VRs) with various configurations.
For example, try:
	mkdir ImageScripts-build; cd ImageScripts-build

	#generate a VR image with a simple monolithic VR
    	sh ../ImageScripts/monolithic.sh

	#copy the generated image to a pendrive
	#WARNING: the pendrive will be erased!
	dd if=test.img of=<your pendrive> bs=1M

Note that the research/innovation leading to these results has received
funding from the European Union under the KIC EIT ICT Labs Action
Smart Ubiquitous Contents ("SmartUC") No. 12180,
Action Line ANSM - Network Solution for Future Media.
