Build the base image
---
To use this you need to have ```make``` installed on your system. Alternatively you can also reference the Makefile itself and run the commands manually.  
You only want to alter the base image if you need to alter the dependencies, which you can also do in the Dockerfile in the root of this repo, but at the cost of build-time.

You can simply build this base image by running `make build`  
If you wish to configure the registry, user or tag you can do so by adding the parameters to the command like `make build user=exampleuser registry=example.com tag=exampletag`  

To use your newly made image you have to adapt the Dockerfile in the above directory and replace the ```FROM docker.io/sirrgb/dockdroid-base:latest``` statement with ```FROM example.com/exampleuser/dockdroid-base:exampletag```  
If you want to make your changes public you can run ```docker login example.com``` where example.com is your chosen registry and follow the given instructions. The same works for podman. ```make publish``` will push the image to that registry with your chosen tag and latest.
