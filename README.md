The objective of this code is to estimate global coordinates of the reference forces and moments at the hands, to be applied to JBD's V3D model 
Important to note that the coordinates of xp and yp are in the PY6's coordinate system 

The lab-based coordinate system is the global coordinate system (GCS). We placed calibration markers on the Bertec PY6 force cube, which was connected to a palletizing push rig handle 

What we know
- We have the GCS [100;010;001]
- We can create the PY6 local coordinate system (LCS) in space, expressed in global coordinates
- We can generate local coordinates of the force applied to the PY6 (xp, yp) generated from the force and moment outputs
- We have the fixed distance from the point of force application on the surface of the PY6 to the end of the handle (111mm)

Steps to complete objective 
- Create an LCS of the PY6 orientation in 3D space for each notch setting (1-10)
- Create L2G transformation matrices to express local coordinates of the PY6 forces in global space for each notch setting
- Apply L2G transformations to the force trials based on the notch settings 
