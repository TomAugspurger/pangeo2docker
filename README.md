Prototype image builder for pangeo


Don't use this! You want https://repo2docker.readthedocs.io/en/latest/ instead.

## Values

1. Minimize image size

   Smaller images are better. Faster cold-start time, and smoother adaptive
   workflow. r2d trades image size for convenience in a few places we don't need.

2. Keep it simple to maintain

   I haven't invested much time in understanding how r2d, overlay, and on-build
   works, but as an outsider it seems like a lot of complexity. This reflects
   my own ignorance in this area, rather than a failing of r2d. 

3. Extensible

   Pangeans using this should be able to extend it with a subset of the
   r2d extension points. `environment.yaml`, apt.txt, etc.

## The Plan

`pangeo2docker` takes the common r2d fils (apt.txt, environment.yml, postBuild, start)
and generates a dockerfile from there. Compared to r2d, it should have fewer layers
and be smaller since we're trying to do less.

Notably, we haev a single `conda install` command with all the packages from
the user's `environment.yaml` merged with the required, base packages. This gives
us faster builds, since conda can struggle to solve things when installing new
packages into an existing environment.

Finally, I experimented with conda's standalone executable. This avoids creating
a "base" environment, so it save a handful of MB. It causes other headaches though.
