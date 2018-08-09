//PLEASE NOTE: THIS SHADER DOES NOT SUPPORT LIGHTMAPPING!
//DO NOT TRY AND USE THIS SHADER ON YOUR WORLDS, IT IS ONLY MEANT FOR AVATARS.

Hi! Thanks for using my Shader pack! 

My goal when setting out to make a toon shader was to make one that looked not only good,
but did so in all conditions, no matter how bad the lighting in any given scene may be. 

This shader may not be perfect! Below, you will find a set of valuable information and stuff about the shader and its varients! 

You can join my Discord server where I will be releasing periodic updates and taking bug reports over at this link: https://discord.gg/M6MGNnT

DISCLAIMER: TO GET BAKED LIGHTING SETTINGS TO SHOW ANY CHANGES YOU'RE MAKING, YOU MUST DISABLE ANY REALTIME LIGHTS IN YOUR SCENE, 
OTHERWISE YOU WILL NOT SEE ANY CHANGES REALTIME.

There are eight shader in total, you can find them located in the "Main" folder.

They are as follows. 

Opaque Shaders:
        XSToon - 
            For things that don't need to be transparent, this contains opaque and cutout blend modes.

        XSToon Cutout -
            This is for cutout transparency, meant to be used for things that don't need soft edges.

        XSToon Transparent Dithered - 
            This is essentially an Opaque shader, but it discards pixels in a pattern to give the illusion of transparency. The upside to this is that 
            you retain the ability to recieve shadowing.

Transparent Shaders:
        XSToon Transparent - 
            This is standard transparency meant to be used with things like particles.

        XSToon Fade - 
            Meant to be used for things like face emotes, blushes, that kind of thing. This blend mode will basically be a cutout with soft edges.

        XSToon Transparent Shadowed - 
            This is standard transparency, but will recieve shadows. The downside to this workaround is that you will not be able to layer transparent objects properly with this.
            I.E. your transparent object will cut out other transparent objects. 
        
        XSToon Fade Shadowed - 
            The same as fade, but recieves shadows. Has the same downside as Transparent Shadowed. 

Extra Shaders:
        XSToon Stenciler - 
            This is to be used in conjunction with the advanced options on other varianets. Info is below labelled "STENCIL TUTORIAL."



In the Textures folder, you will find a folder for Specular Patterns, and a folder for Shadow Ramps.
Alongside that you will find a folder for Reflection Cubemaps, and for Matcap Patterns. 

The Specular Patterns are what shows up in the highlights on your model. You can use any image you want, but it works best with a tiling grayscale pattern.

I have included a few interesting ones by default, but I encourage you to be expirmental. Make your own, download some, etc.

        The Shadow Ramps are to go in the Color Ramp slot in all shader varients. This is needed if you want shadows. 

        The ramp can be sharp or smooth. If you want toon shading, you'd make it a sharp ramp. E.X. "TwoToneRamp" or "ThreeToneRamp"

        If you want smooth shading, just do a smooth black to white gradient.

        I would recommend not going to full black on any ramps, as that can cause lighting problems in very dark rooms. 
            (Though its not the end of the world, I just think it looks bad)

        I have included a few basic ramps in the ramps folder so that you can get a base idea of how they work.

        Oh, and my Shader supports both vertical and horizontal ramps out of the box. That means you can transfer any over from MMD or whatever else you may be getting shadow ramps from.

    If you make your own, it is best that you set the texture to "Clamp" under the import settings, as it could cause some issues if it's not.

The final option is the "Simulated Light Direction." 
    My shader detects if there is a realtime light affecting you, and if there is, it uses that.
    If there is no light, it uses a baked in direction that you choose using "Simulated Light Direction."
        To properly test this, you should disable any realtime lights in your scene. 
        It will not change otherwise, since it will be using the realtime light's direction.


Finally, I have included a material called "Material example" that is set up to use settings that I personally like and feel look good,
should you need it as reference, I recommend not changing it without duplicating it first. 

Enjoy!

P.S. If your shadows ever go entirely black, blame the map maker for not properly setting up lighting in the map. 
This is only a problem if Ambient light color is set to black, and there are no light probes. The way my shader shows this is indeed accurate.


STENCIL TUTORIAL:

    The stencil shader and advanced options both contain a bunch of options for stenciling. Let's set up a basic example with that - say you have an orb, 
    and you want to hide yourself behind the orb! 

    This can be accomplished by making a sphere, and putting the XSToon stencil shader on it. 
    Then, under the settings, go ahead and set ColorMask to none, and make sure ZWrite is set to OFF.
    This will make it invisible. This is good, we're on the right track!

    Now, let's pick a number to reference. In my case, I used 90. It can be any number from 1-255. Input your number at the top, under "Stencil ID"

    Now, we're done with the setup for that. Let's go to the material for the thing we want to cut out. 

    Under "Shader Mode", select "Advanced" to show all of the options for stenciling. 
    
    Set your Stencil ID to whatever number you chose before, in my case, it was 90.

    Set Stencil Comparison to "NotEqual". This will make it so that the orb will now cut out a hole in whatever your material is on.

    If you want to have the reverse effect, and only show your object when it's behind the orb, just swap it from "NotEqual" to "Equal".

    And that's it, you've got a simple "Cutout" or "Portal" effect. 


Note: For all shader varients, Use UV2 is only for models that have a second UV channel for the Normal map and Specular map, 
leave this unchecked unless you're positive you have this.

/////////////////////////////
FOR ADVANCED USERS:

This shader was made using amplify, but has been heavily rewritten, as it was needed to increase performance and fix lighting issues that were caused
by amplifies limited power. 

I strongly recommend you to not open it in Amplify, as it will probably break. It is best to just edit the code. You can find the entire lighting model in XSToonBase.cginc

Once you make a change to that, it will change all of the rest of the shaders as it is included as the base code for each variant.

////////////////////////////