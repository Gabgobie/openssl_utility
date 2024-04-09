# openssl_utility
Just a little CLI utility I made for myself to make certifiacte management a little easier.


This is my first project and the first time I code in Bash. I'd appreciate a little patience for the mistakes/suboptimal implementations in this project. Any recommendations are appreciated. I decided on using Bash to avoid having to install any additional runtime environemnts on my system.

## Dependencies

At this moment the project is dependent on:
- dpkg
- apt
- awk (gawk but I believe mawk should work as well?)
- openssl (of course)

## Usage

Make the main.sh executable by running ```chmod 700 ./main.sh``` from the same directory you downloaded the repository into, change all values inside the values directory to meet your needs and run the main.sh. I believe I made it echo everything you need to know at the corresponding points in the script. The important variables will be set in the [ default ] section of the respective openssl config files but there are some more variables like for example default values for additional fields of your certificates some lines down the file.

You can put your own bash scripts into the extensions folder and they should be picked up on launch. To keep things clean I don't recommend throwing anything in there but scripts for certificate creation for example with different cryptographic algorithms. I'd of course appreciate if you shared your creation/management scripts in a PR. You could use the underlying mechanics from the main.sh to power any of your script collections.

## Is the project maintained?

I have started working on a Python reboot of this project. I don't expect it to stop working anytime soon but I will probably drop this version of the project for now. It should still be sufficient to initialize your PKI but I would probably not trust it to handle it after that (even though it probably could). Ensure you have a backup of your PKI when working with this. I will add a link to the reboot as soon as it is mature enough.
