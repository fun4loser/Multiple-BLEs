# Multiple BLE connections.

This Xcode applet will scan for Bluetooth Low Energy devices in your vicinity. There is a way to limit the scan to devices with a certain prefix (var desiredDeviceName) if you're developing a Bluetooth component of your own and only wish to look for it.

It will allow you to connect to up to two devices and store the values of their characteristics, convert them from big endian and little endian to doubles, and display the output visually.

This was developed with a particular project in mind involving a controller in each hand, but parts of the code could be scaled to fit the purpose of other BLE related projects.
