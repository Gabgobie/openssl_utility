# openssl_utility
Just a little CLI utility I made for myself to make certifiacte management a little easier.


This is my first project and the first time I code in Bash. I'd appreciate a little patience for the mistakes/suboptimal implementations in this project. Any recommendations are appreciated. I decided on using bash to avoid having to install any additional runtime environemnts on my system.

## Dependencies

At this moment the project is dependant on:
- dpkg
- apt
- awk (gawk but I believe mawk should work as well?)
- openssl (of course)

## Usage

Make the main.sh executable by running ```chmod 700 ./main.sh``` from the same directory you downloaded the repository into, change all values inside the values directory to meet your needs and run the main.sh. I believe I made it echo everything you need to know at the corresponding points in the script. The important variables will be set in the [ default ] section of the respective openssl config files but there are some more variables like for example default values for additional fields of your certificates some lines down the file.

You can put your own bash scripts into the extensions folder and they should be picked up on launch. To keep things clean I don't recommend throwing anything in there but scripts for certificate creation for example with different cryptographic algorithms. I'd of course appreciate if you shared your creation/management scripts in a PR. You could use the underlying mechanics from the main.sh to power any of your script collections.

## Is the project maintained?

Due to time constraints I will likely not spend a lot of time with this project after it has fulfilled its purpose but I will ofc look into any PRs and Issues every once in a while. Sometimes there may however be an unexpected update whenever I find the time to add features I wished to have all along. In the unlikely case of some breaking change in openssl I will update this to work again as I intend on using this a couple times per year. After all it's just a script that's supposed to make handling openssl a little easier. I just felt like sharing this in case anybody actually had a use for it.