# Image Recognition with ResNet50, ResNet101 and InceptionV3


## Goal
This tutorial will introduce CPU performance considerations for three image recognition deep learning models, and how to use Intel’s TensorFlow 
optimizations to improve inference time on CPU. This tutorial will also provide code examples to use Model Zoo's pretrained model that can be copy/pasted for quick off-the-ground implementation with synthetic and real data.

## Background
Image recognition with deep learning is a computationally expensive endeavor. 
This tutorial will show you how to reduce the inference runtime of your network. 
Convolutional neural networks (CNNs) have been shown to learn and extract usable features by layering many convolution filters. ResNet50, ResNet101 and InceptionV3 are among the popular topologies for image recognition in the industry today.
There are 2 main setbacks for CNNs for performance:
1. Deeply layering convolutions causes the number of training parameters to increase drastically.
2. Linear convolution filters cannot learn size-invariant features without using separate filter for each size regime.

ResNet models use gate and skip logic to address issue #1 and lower the number of parameters, similar to a recurrent neural network (RNN). The InceptionV3 model utilizes “network in network” mini perceptrons to convert linear convolutions into non-linear convolutions in a compact step, addressing issue #2. InceptionV3 also includes optimization that factor and vectorize the convolutions, further increasing the speed of the network.

##  Recommended Settings 

In addition to TensorFlow optimizations offered by Intel MKLDNN in Intel-optimized TensorFlow to utilize instructions sets appropriately, the runtime settings also significantly contribute to improved performance. Tuning these options to optimize CPU workloads is vital to enable max performance out of Intel Optimization of TensorFlow. 
Below are the set of run-time options recommended by Intel on
ResNet50, ResNet101 and InceptionV3 through empirical testing.  


<table class="tg">
  <tr>
    <th class="tg-amwm" rowspan="2">Run-time options</th>
    <th class="tg-amwm" colspan="3">Recommendations</th>
  </tr>
  <tr>
    <td class="tg-amwm">ResNet50</td>
    <td class="tg-amwm">InceptionV3</td>
    <td class="tg-amwm">ResNet101</td>
  </tr>
  <tr>
    <td class="tg-0lax">Batch Size</td>
    <td class="tg-baqh" colspan="3">128. Regardless of the hardware</td>
  </tr>
  <tr>
    <td class="tg-0lax">Hyperthreading</td>
    <td class="tg-baqh" colspan="3">Enabled. Turn on in BIOS. Requires a restart.</td>
  </tr>
  <tr>
    <td class="tg-0lax">intra_op_parallelism_threads</td>
    <td class="tg-baqh">#physical cores per socket</td>
    <td class="tg-baqh">#physical cores per socket</td>
    <td class="tg-baqh"># all physical cores</td>
  </tr>
  <tr>
    <td class="tg-0lax">inter_op_parallelism_threads</td>
    <td class="tg-baqh">1</td>
    <td class="tg-baqh">1</td>
    <td class="tg-baqh">2</td>
  </tr>
  <tr>
    <td class="tg-0lax">Data Layout</td>
    <td class="tg-baqh" colspan="3">NCHW</td>
  </tr>
  <tr>
    <td class="tg-0lax">NUMA Controls</td>
    <td class="tg-baqh" colspan="2">numactl --cpunodebind=0  --membind=0</td>
    <td class="tg-baqh"></td>
  </tr>
  <tr>
    <td class="tg-0lax">KMP_AFFINITY</td>
    <td class="tg-baqh" colspan="3">KMP_AFFINITY=granularity=fine,verbose,compact,1,0</td>
  </tr>
  <tr>
    <td class="tg-0lax">KMP_BLOCKTIME</td>
    <td class="tg-baqh" colspan="3">1</td>
  </tr>
  <tr>
    <td class="tg-0lax">OMP_NUM_THREADS</td>
    <td class="tg-baqh" colspan="2"># intra_op_parallelism_threads</td>
    <td class="tg-baqh">#physical cores per socket</td>
  </tr>
</table>
<br>

*Note: Refer to the [link](https://software.intel.com/en-us/articles/maximize-tensorflow-performance-on-cpu-considerations-and-recommendations-for-inference) here to learn in-detail about the run time options.*

Run the following commands to get your processor information

a. #physical cores per socket : 
`lscpu | grep "Core(s) per socket" | cut -d':' -f2 | xargs`

b. #all physical cores: 
`lscpu -b -p=Core,Socket | grep -v '^#' | sort -u | wc -l`
 
Below is a code snippet you can incorporate into your existing ResNet50 or ResNet101 or InceptionV3 TensorFlow application to set the best settings. 
You can either set them in the CLI or in the Python script. Note that inter and intra_op_parallelism_threads settings can only be set 
in the Python script

```bash
export OMP_NUM_THREADS=physical cores
export KMP_AFFINITY="granularity=fine,verbose,compact,1,0"
export KMP_BLOCKTIME=1
export KMP_SETTINGS=1
```
(or)
```
import os
os.environ["KMP_BLOCKTIME"] = "1"
os.environ["KMP_SETTINGS"] = "1"
os.environ["KMP_AFFINITY"]= "granularity=fine,verbose,compact,1,0"
if FLAGS.num_intra_threads > 0:
  os.environ["OMP_NUM_THREADS"]= # <physical cores>
config = tf.ConfigProto()
config.intra_op_parallelism_threads = # <physical cores>
config.inter_op_parallelism_threads = 1
#config.inter_op_parallelism_threads = 2 # for ResNet101
tf.Session(config=config)
```

## Hands-on Tutorial
This section shows how to do measure inference performance on Intel's Model Zoo pretrained model( or your pretrained model) by setting the above-discussed run time flags. 
### FP32 inference
 
### Initial Setup
1. Clone IntelAI models and download into your home directory

```bash
git clone https://github.com/IntelAI/models.git
```

2. (Skip to the next step if you already have a pretrained model) Download the pretrained models ```resnet50_fp32_pretrained_model.pb```, ```resnet101_fp32_pretrained_model.pb``` and
```inceptionv3_fp32_pretrained_model.pb``` into your home directory or
any other directory of your choice. 

```
wget https://storage.googleapis.com/intel-optimized-tensorflow/models/resnet50_fp32_pretrained_model.pb

wget https://storage.googleapis.com/intel-optimized-tensorflow/models/resnet101_fp32_pretrained_model.pb

wget https://storage.googleapis.com/intel-optimized-tensorflow/models/inceptionv3_fp32_pretrained_model.pb
```
Refer to following Readme files to get the latest locations of pretrained models <br>
a. [ResNet50](https://github.com/IntelAI/models/tree/master/benchmarks/image_recognition/tensorflow/resnet50) <br>
b. [ResNet101](https://github.com/IntelAI/models/tree/master/benchmarks/image_recognition/tensorflow/resnet101) <br>
c. [InceptionV3](https://github.com/IntelAI/models/tree/master/benchmarks/image_recognition/tensorflow/inceptionv3) <br>

3. (optional) Download and setup directory location for ```real_dataset``` folder that has image files in TFrecord format if you are inferring on real-dataset. You can refer to [ImageNet](https://github.com/tensorflow/models/tree/master/research/slim#an-automated-script-for-processing-imagenet-data) / [Coco Dataset](http://cocodataset.org/#home) that has images converted to TFrecords
(or) you can run the [build_image_data.py](https://github.com/tensorflow/models/blob/f87a58cd96d45de73c9a8330a06b2ab56749a7fa/research/inception/inception/data/build_image_data.py) to convert raw images into TFRecords.

4. Install [Docker](https://docs.docker.com/v17.09/engine/installation/) since the tutorial runs on a Docker container

### Run inference

1. Pull the relevant Intel-optimized TensorFlow Docker image. We'll be running the pretrained model to infer on Docker container
. [Click here](https://software.intel.com/en-us/articles/intel-optimization-for-tensorflow-installation-guide) to find  all the available Docker images
```bash
docker pull docker.io/intelaipg/intel-optimized-tensorflow:latest
```
2. cd to the inference script directory
```bash        
cd ~/models/benchmarks
```
3. Run the Python script ``` launch_benchmark.py``` with the pretrained model. 
```launch_benchmark.py``` script can be treated as an entry point to conveniently perform out-of-box high performance 
inference on pretrained models trained of popular topologies. 
The script will automatically set the recommended run-time options for supported topologies, 
but if you choose to set your own options, refer to full of available flags and a detailed
explanation on ```launch_benchmark.py``` script [here](/docs/general/tensorflow/LaunchBenchmark.md).
This step will automatically launch a new container on every run and terminate. Go to the [Step 4](#step_4) to interactively run the script on the container.

3.1. <b> *Real Time inference*</b>(batch_size=1 for latency)

3.1.1 <b>ResNet50</b>

Note: As per the recommended settings `socket-id` is set to 0 for ResNet50. The workload will run on a single socket with `numactl` enabled. Remove the flag or set it to -1 to disable it.


 *Synthetic data*
	
	python launch_benchmark.py \
		--in-graph ~/resnet50_fp32_pretrained_model.pb \
		--model-name resnet50 \
		--framework tensorflow \
		--precision fp32 \
		--mode inference \
		--batch-size 1 \
		--benchmark-only \
		--socket-id 0 \
		--docker-image intelaipg/intel-optimized-tensorflow:latest 

*Real data*

	python launch_benchmark.py \
		--data-location ~/real_dataset \
		--in-graph ~/resnet50_fp32_pretrained_model.pb \
		--model-name resnet50 \
		--framework tensorflow \
		--precision fp32 \
		--mode inference \
		--batch-size 1 \
		--benchmark-only \
		--socket-id 0 \
		--docker-image intelaipg/intel-optimized-tensorflow:latest

3.1.2 <b>ResNet101</b>


*Synthetic data*
	
	python launch_benchmark.py \
		--in-graph ~/resnet101_fp32_pretrained_model.pb \
		--model-name resnet101 \
		--framework tensorflow \
		--precision fp32 \
		--mode inference \
		--batch-size 1 \
		--benchmark-only \
		--docker-image intelaipg/intel-optimized-tensorflow:latest 

*Real data*

	python launch_benchmark.py \
		--data-location ~/real_dataset \
		--in-graph ~/resnet101_fp32_pretrained_model.pb \
		--model-name resnet101 \
		--framework tensorflow \
		--precision fp32 \
		--mode inference \
		--batch-size 1 \
		--benchmark-only \
		--docker-image intelaipg/intel-optimized-tensorflow:latest

3.1.3 <b>InceptionV3</b>

Note: As per the recommended settings `socket-id` is set to 0 for InceptionV3. The workload will run on a single socket with `numactl` enabled. Remove the flag or set it to -1 to disable it.

*Synthetic data*
	
	python launch_benchmark.py \
		--in-graph ~/inceptionv3_fp32_pretrained_model.pb \
		--model-name inceptionv3 \
		--framework tensorflow \
		--precision fp32 \
		--mode inference \
		--batch-size 1 \
		--benchmark-only \
		--socket-id 0 \
		--docker-image intelaipg/intel-optimized-tensorflow:latest 

*Real data*

	python launch_benchmark.py \
		--data-location ~/real_dataset \
		--in-graph ~/inceptionv3_fp32_pretrained_model.pb \
		--model-name inceptionv3 \
		--framework tensorflow \
		--precision fp32 \
		--mode inference \
		--batch-size 1 \
		--benchmark-only \
		--socket-id 0 \
		--docker-image intelaipg/intel-optimized-tensorflow:latest

3.2. <b>*Best Throughput inference*</b>(batch_size=128 for throughput)

3.2.1 <b>ResNet50</b>

Note: As per the recommended settings `socket-id` is set to 0 for ResNet50. The workload will run on a single socket with `numactl` enabled. Remove the flag or set it to -1 to disable it.


 *Synthetic data*
	
	python launch_benchmark.py \
		--in-graph ~/resnet50_fp32_pretrained_model.pb \
		--model-name resnet50 \
		--framework tensorflow \
		--precision fp32 \
		--mode inference \
		--batch-size 128 \
		--benchmark-only \
		--socket-id 0 \
		--docker-image intelaipg/intel-optimized-tensorflow:latest 

*Real data*

	python launch_benchmark.py \
		--data-location ~/real_dataset \
		--in-graph ~/resnet50_fp32_pretrained_model.pb \
		--model-name resnet50 \
		--framework tensorflow \
		--precision fp32 \
		--mode inference \
		--batch-size 128 \
		--benchmark-only \
		--socket-id 0 \
		--docker-image intelaipg/intel-optimized-tensorflow:latest

3.2.2 <b>ResNet101</b>


*Synthetic data*
	
	python launch_benchmark.py \
		--in-graph ~/resnet101_fp32_pretrained_model.pb \
		--model-name resnet101 \
		--framework tensorflow \
		--precision fp32 \
		--mode inference \
		--batch-size 128 \
		--benchmark-only \
		--docker-image intelaipg/intel-optimized-tensorflow:latest 

*Real data*

	python launch_benchmark.py \
		--data-location ~/real_dataset \
		--in-graph ~/resnet101_fp32_pretrained_model.pb \
		--model-name resnet101 \
		--framework tensorflow \
		--precision fp32 \
		--mode inference \
		--batch-size 128 \
		--benchmark-only \
		--docker-image intelaipg/intel-optimized-tensorflow:latest

3.2.3 <b>InceptionV3</b>

Note: As per the recommended settings `socket-id` is set to 0 for InceptionV3. The workload will run on a single socket with `numactl` enabled. Remove the flag or set it to -1 to disable it.

*Synthetic data*
	
	python launch_benchmark.py \
		--in-graph ~/inceptionv3_fp32_pretrained_model.pb \
		--model-name inceptionv3 \
		--framework tensorflow \
		--precision fp32 \
		--mode inference \
		--batch-size 1 \
		--benchmark-only \
		--socket-id 0 \
		--docker-image intelaipg/intel-optimized-tensorflow:latest 

*Real data*

	python launch_benchmark.py \
		--data-location ~/real_dataset \
		--in-graph ~/inceptionv3_fp32_pretrained_model.pb \
		--model-name inceptionv3 \
		--framework tensorflow \
		--precision fp32 \
		--mode inference \
		--batch-size 1 \
		--benchmark-only \
		--socket-id 0 \
		--docker-image intelaipg/intel-optimized-tensorflow:latest
		

<u>Console Output</u>

	[Running warmup steps...]
	steps = 10, 460.862674539 images/sec
	[Running benchmark steps...]
	steps = 10, 461.002369109 images/sec
	steps = 20, 460.082656541 images/sec
	steps = 30, 464.707827579 images/sec
	steps = 40, 463.187506632 images/sec
	steps = 50, 462.725212176 images/sec
	lscpu_path_cmd = command -v lscpu
	lscpu located here: /usr/bin/lscpu
	Ran inference with batch size 128
	Log location outside container: {--output-dir value}/benchmark_resnet50
	

The logs are captured in a directory outside of the container.<br> 


4. <a name="step_4"></a>If you want to run the benchmarking script interactively within the docker container, run ```launch_benchmark.py``` with ```--debug``` flag. This will launch a docker container based on the ```--docker_image```,
performs necessary installs, runs the ```launch_benchmark.py``` script and does not terminate the container process. As an example, this step will demonstrate ResNet50 Real Time inference on Synthetic Data use case, 
you can implement the same strategy on different use cases demoed in Step 3.
		
		python launch_benchmark.py \
			--in-graph ~/resnet50_fp32_pretrained_model.pb \
			--model-name resnet50 \
			--framework tensorflow \
			--precision fp32 \
			--mode inference \
			--batch-size 1 \
			--benchmark-only \
			--docker-image intelaipg/intel-optimized-tensorflow:latest \
			--debug 				
	
<u>Console output</u>
	
	lscpu_path_cmd = command -v lscpu
	lscpu located here: b'/usr/bin/lscpu'
	root@a78677f56d69:/workspace/benchmarks/common/tensorflow#
	
To rerun the bechmarking script, execute the ```start.sh``` bash script from your existing directory with additional or modified flags. For e.g  to rerun with the best max throughput (batch size=128) settings run with ```BATCH_SIZE``` 
and to skip the run from reinstalling packages pass ```True``` to ```NOINSTALL```. 
	
	chmod +x ./start.sh
	
	
	NOINSTALL=True BATCH_SIZE=128 ./start.sh
	
All other flags will be defaulted to values passed in the first ```launch_benchmark.py``` that starts the container. [See here](google.com) to get the full list of flags. 
	
<u>Console output</u>	
	
    USE_CASE: image_recognition
    FRAMEWORK: tensorflow
    WORKSPACE: /workspace/benchmarks/common/tensorflow
    DATASET_LOCATION: /dataset
    CHECKPOINT_DIRECTORY: /checkpoints
    IN_GRAPH: /in_graph/freezed_resnet50.pb
    Mounted volumes:
        /localdisk/myuser/intel-models/benchmarks mounted on: /workspace/benchmarks
        None mounted on: /workspace/models
        /localdisk/myuser/intel-models/benchmarks/../models/image_recognition/tensorflow/resnet50 mounted on: /workspace/intelai_models
        None mounted on: /dataset
        None mounted on: /checkpoints
    SOCKET_ID: -1
    MODEL_NAME: resnet50
    MODE: inference
    PRECISION: fp32
    BATCH_SIZE: 128
    NUM_CORES: -1
    BENCHMARK_ONLY: True
    ACCURACY_ONLY: False
    NOINSTALL: True
	.
	.
	.
	.
	.
	Batch size = 128
	Throughput: 115.107 images/sec
	lscpu_path_cmd = command -v lscpu
	lscpu located here: /usr/bin/lscpu
	Ran inference with batch size 128
	Log location outside container: {--output-dir value}/benchmark_resnet50_inference_fp32_20190205_201632.log
	
	

	
	

