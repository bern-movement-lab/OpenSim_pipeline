all: Partload

Partload: Partload15kg Partload100

Partload15kg: Partload15kg_2to8 Partload15kg_9to15 Partload15kg_16to21

Partload15kg_2to8:
	matlab -batch "partload_pipeline_walk15kg_2to8"

Partload15kg_9to15:
	matlab -batch "partload_pipeline_walk15kg_9to15"

Partload15kg_16to21:
	matlab -batch "partload_pipeline_walk15kg_16to21"

Partload100: Partload100_2to8 Partload100_9to15 Partload100_16to21

Partload100_2to8:
	matlab -batch "partload_pipeline_walk100_2to8"

Partload100_9to15:
	matlab -batch "partload_pipeline_walk100_9to15"

Partload100_16to21:
	matlab -batch "partload_pipeline_walk100_16to21"

clean:
	rm -f opensim.log