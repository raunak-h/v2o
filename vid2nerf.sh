#!/usr/bin/bash

#set -e

if [ -z "$1" ]; then
    echo "No NERFs given? :P"
    exit 1
fi

#ORGANISE DATA
root_dir=~/v2o/data
cd $root_dir

if [ -f $1/inputvideo/$1.mp4 ]; then
    mv $root_dir/$1/inputvideo/$1.mp4 $root_dir/
    rm -r inputvideo output images 2> /dev/null
fi

mkdir -p $root_dir/$1/inputvideo $root_dir/$1/images $root_dir/$1/output
mv $root_dir/$1.mp4 $root_dir/$1/inputvideo/
cd $root_dir/$1

# FFMPEG
duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 inputvideo/$1.mp4 | cut -d '.' -f 1)
framerate=$((120/duration))
ffmpeg -i inputvideo/$1.mp4 -r $framerate images/img%03d.jpg

# COLMAP
colmap feature_extractor --SiftExtraction.estimate_affine_shape=true --SiftExtraction.domain_size_pooling=true --ImageReader.single_camera 1 --database_path colmap.db --image_path images
colmap exhaustive_matcher --SiftMatching.guided_matching=true --database_path colmap.db
mkdir sparse
colmap mapper --database_path colmap.db --image_path images --output_path sparse
colmap bundle_adjuster --input_path sparse/0 --output_path sparse/0 --BundleAdjustment.refine_principal_point 1
mkdir colmap_text
colmap model_converter --input_path sparse/0 --output_path colmap_text --output_type TXT

# TRANSFORMS.JSON
python3 ~/v2o/colmap2nerf.py --aabb_scale 2
python3 ~/v2o/instant-ngp/scripts/run.py --save_snapshot ~/v2o/data/$1/output/$1.ingp --save_mesh ~/v2o/data/$1/output/$1.obj --marching_cubes_res 256 ~/v2o/data/$1/

# MARCHING CUBES
# TBD

# MESHLAB VISUALISATION
cd ~/v2o/
./MeshLab2022.02-linux.AppImage ~/v2o/data/$1/output/$1.obj
