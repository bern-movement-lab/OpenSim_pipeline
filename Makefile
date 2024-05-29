export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6:/usr/lib/x86_64-linux-gnu/libgfortran.so.5:/usr/lib/x86_64-linux-gnu/libopenblas.so

all: Partload

Partload: Partload15kg Partload100

Partload15kg: Partload15kg_2to8 Partload15kg_9to15 Partload15kg_16to21

Partload15kg_2to8:
	/usr/local/MATLAB/R2021a/bin/matlab -batch "partload_pipeline_walk15kg_2to8"

Partload15kg_9to15:
	/usr/local/MATLAB/R2021a/bin/matlab -batch "partload_pipeline_walk15kg_9to15"

Partload15kg_16to21:
	/usr/local/MATLAB/R2021a/bin/matlab -batch "partload_pipeline_walk15kg_16to21"

Partload100: Partload100_2to8 Partload100_9to15 Partload100_16to21

Partload100_2to8:
	/usr/local/MATLAB/R2021a/bin/matlab -batch "partload_pipeline_walk100_2to8"

Partload100_9to15:
	/usr/local/MATLAB/R2021a/bin/matlab -batch "partload_pipeline_walk100_9to15"

Partload100_16to21:
	/usr/local/MATLAB/R2021a/bin/matlab -batch "partload_pipeline_walk100_16to21"

Partload15kg_100:
	/usr/local/MATLAB/R2021a/bin/matlab -batch "partload_pipeline_walk15kg_walk100"

nothing: 
	echo "Nothing"

clean:
	rm -f opensim.log