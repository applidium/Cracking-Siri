Here are the tools we wrote to reverse-engineer Siri.

The code is extremely dirty as it was written, erased, written again, and is a pure product of a trial-and-error process.
Anyway, here's a simple how-to if you want to have fun with it :

h3. How to get the necessary bits

# Generate a certificate authority
# Add it to your iPhone
# Sign a certificate for "guzzoni.apple.com" using that authority. This should produce the ".crt" and ".key" files your server will need.
# Setup a fake DNS server that resolves "guzzoni.apple.com" to your own machine, and configure your iPhone to use it.
# Start the "siriServer.rb" server. You will need some ruby gem installed. I have tested it only on Mac OS X 10.7.2 with Ruby 1.9.2.
# Make Siri dictation request, for example from the Notes.app application. On the server, this will dump all the "interesting" bits (X-Ace-Host identifier, sessionData and such).
# Use them to replace instances of "COMMENTED_OUT" in the code

h3. How to do speech-to-text using a non-iPhone4S machine

# Record your voice into whatever format you like
# Use ffmpeg to convert the sound to raw sound samples (see the text file for the exact command line). Name it "tentative.raw"
# Install the speex library and its header. On Mac OS X, "brew install speex" once you've setup Homebrew
# Compile the speexEnc.m file (gcc speexEnc.m -lspeex -framework Foundation -o speexEnc)
# Run ./speexEnc. It will produce a input.sif file with speex packets the Ruby script will be able to read
# Run the "Siri.old.inline.rb" script. Et voilà !
