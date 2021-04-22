# salamandr-play

Early, early alpha -- Please use at your own risk

A simple sample slicer for norns.

Inspired by sam and norman, written using `softcut`.

## Documentation

1. Load the sample to be sliced from params
2. (Optional) specify the name for the folder containing the sliced samples. The specified name will also be the prefix in the name of each slice``"name"+number.wav``. If no name is specified, the name of the loaded sample file at step 1 will be used. 
3. Specify the number of slices (default is 16).
4. Return to the script. You will see a waveform. **NOTE**: UI is still very much under construction. 
5. On the main screen:
- E1 scrolls through the slices
- E2 affects the start time of the selected slice (K1+E2 enables fine adjustments)
- E3 affects the end time of the selected slice (K1+E3 enables fine adjustments)
- K1+K2 starts playing the selected slice on loop. Press K1+K2 again to stop playback.
- K3 saves the slices
- K1+K3 starts playing the whole sample slice by slice; K1+K3 stops playback
6. Slices are saved in a folder in `dust/audio/salamandr', according to the name specified at Step 2 or the name of the loaded sample. 

## Installs

from maiden:

`;install https://github.com/fardles/salamandr-play`



