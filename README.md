#Multiple BLE connections.

This xcode applet will scan for Bluetooth Low Energy devices in your vicinity. There is a way to limit the scan to devices with a certain prefix (prefix name here) if you're developing a bluetooth component yourself.

It will allow you to connect to upto two devices and store the values of their charachteristics, convert them from big endian and little endian to doubles, and display the output visually.

This was developed with a particular project in mind involving dual hand controllers, but parts of the code could be scalled to fit the purpose of other BLE related projects.