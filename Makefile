all: Partload

Partload: Partload15kg Partload100
	
Partload15kg:
	matlab -batch "partload_pipeline_walk15kg"

Partload100:
	matlab -batch "partload_pipeline_walk100"

Partload15kg_14to21:
	matlab -batch "partload_pipeline_walk15kg_14to21"

Partload100_14to21:
	matlab -batch "partload_pipeline_walk100_14to21"

clean:
	rm -f /home/patric/fast/matlab-output/Partload/*