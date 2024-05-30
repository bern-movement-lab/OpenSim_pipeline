export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6:/usr/lib/x86_64-linux-gnu/libgfortran.so.5:/usr/lib/x86_64-linux-gnu/libopenblas.so

all: Partload

Partload: Partload15kg Partload100

Partload15kg_100:
	/usr/local/MATLAB/R2021a/bin/matlab -batch "partload_pipeline_walk15kg_walk100"

Partload15kg:
	/usr/local/MATLAB/R2021a/bin/matlab -batch "partload_pipeline_walk15kg"

Partload100:
	/usr/local/MATLAB/R2021a/bin/matlab -batch "partload_pipeline_walk100"

nothing: 
	echo "Nothing"

clean:
	rm -f opensim.log