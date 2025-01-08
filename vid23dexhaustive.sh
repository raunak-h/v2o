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
    rm -r !("*.mp4") 2> /dev/null
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
mkdir dense
colmap image_undistorter --image_path images --input_path sparse/0 --output_path dense --output_type COLMAP --max_image_size 2000
colmap patch_match_stereo --workspace_path dense --workspace_format COLMAP --PatchMatchStereo.geom_consistency true
colmap stereo_fusion --workspace_path dense --workspace_format COLMAP --input_type geometric --output_path dense/fused.ply
colmap poisson_mesher --input_path dense/fused.ply --output_path dense/$1_poisson.ply
colmap delauney_mesher --input_path dense/$1_poisson.ply --output_path dense/$1_delauney.ply

# MESHLAB VISUALISATION
cd ~/v2o/
./MeshLab2022.02-linux.AppImage ~/v2o/data/$1/dense/$1_poisson.ply
