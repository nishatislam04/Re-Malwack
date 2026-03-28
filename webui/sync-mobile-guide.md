# This guide is about how to push development changes directly to mobile internal storage to quickly test the changes!

## Follow step by step

1. both of the laptop and the mobile need to be connected to the same wifi network
2. take a note of your mobile wifi ipv4 address
3. go to `connect-to-phone.sh` file and paste your mobile ip address
> note: make sure to connect your device to your laptop with usb (only for first time!) and turn on usb-debug option from your mobile developer settigs.
4. disconnect usb for your mobile
5. hit `pnpm run connect`
6. i hope you got status: connect success. hahaha. you need ROOT!
	7. after success connect, then hit `pnpm run sync` and this will build the assets and transmit the files over the wifi to your mobile at this directory `/storage/emulated/0/Re-malwack-source/`

> this worked for me. and i have rooted device. and i just pasted the workflow for what i have followed. if it does not work for you, please research a bit and if you manage to get it working, please feel free to update this guide
