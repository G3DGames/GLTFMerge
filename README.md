# GLTFMerge

A Pascal Library to read/write GLTF/GLB files and merge them together

### Dependancies - neon JSON library

> git submodule init
> git submodule update

### Code

docs - Documentation

GLTFLib - The library

src - The UI

### Description

GLTFMerge takes a base GLB/GLTF then lets you add secondary supporting files to it.

The most obvious example is where the model and animations are in seperate files. This is frequently done where the exact same skeleton is used by multiple models.
To create one mereged gile open your model then click on the animations tab and add as many animations as you like. By default all animations will be selected but if you only want a subset just "select none" then check the models you actually want.
Save the file somewhere new and you have a combined GLB/GLTF of the model and any selected animations.

A modification of this idea is that you could just make a GLTF output file of only selected subset of some large animation library you desire to use in your project

Another (less frequently ancountered) situation is where you have optional body parts (or other things) that are meanto to go with a specific model. You can open the base model then switch to the "Parts" tab and select as many optional parts as you desire. These will all be loaded and can then be attached to the model by selecting the parts you want to add and clicking the "Use on the Model" button. This will then merge the models together and you can save the new model.





