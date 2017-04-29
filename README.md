# Stringless Guitar
Small FPGA implementation of sound synthesizing

This is a small project that was written years ago when I was exposed
for the first time to FPGA development. I was using a Xilinx Spartan 3-200 Starter Kit
for this design.

This code is **NOT** being mantained - to be fair I don't remember much of this
work. Is only kept in GitHub to have as
a future reference, and maybe to be retaken at some point (which is not
in the near future).

# Brief description of the project

The main idea was to have sound synthesis, while playing with filtering
and register shifting to get 6 different notes that emulate the sound of
a guitar.

After the expected sound was achieved, a small wooden guitar was adapted to
hold the FPGA and small circuitry inside. Instead of using strings as triggers
for the sound, a group of light indicators (the ones you'd use in a presentation)
was adapted to point directly to a set of fotocells, so that everytime you put
your hand in a position that interrupts the reception of light into the cell,
a sound will be triggered, and thereby getting a stringless guitar. The trigger,
before reaching the GPIO ports of the FPGA, was controlled by a small analog
stage and a set of DIACs.
