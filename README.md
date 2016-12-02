Two!Ears Auditory Machine Learning Training and Testing Pipeline
================================================================

The purpose of the Two!Ears Auditory Machine Learning Training and Testing 
Pipeline (AMLTTP) is to build and evaluate models for auditory sound object 
annotation and assigning attributes to them. The models are obtained by 
inductive learning from labeled training data. The framework is tightly 
coupled with the Two!Ears system. 

While the pipeline is designed with flexibility in mind and is extendable to 
new target attributes, data features, or model and training algorithms, it so far
serves the specific purpose of training and evaluation of block-based auditory 
object-type, object-location, and number-of-sources classifiers using data from 
simulated auditory scenes generated within the same framework.


## Installation

The AMLTTP makes use of other software modules of the [Two!Ears
Computational Framework](https://github.com/TWOEARS/). You will need to download 
- https://github.com/TWOEARS/blackboard-system
- https://github.com/TWOEARS/auditory-front-end
- https://github.com/TWOEARS/binaural-simulator
- https://github.com/TWOEARS/SOFA
- https://github.com/TWOEARS/main

In your "main"-directory, please first edit TwoEarsPath.xml to point to your 
respective directories.



## Usage

Once Matlab opened, the source code folders need to be added to the Matlab path. 
This will be accomplished by executing the following commands in:
```Matlab
>> addpath( '<path-to-your-TwoEars-Main-directory>' )
>> startAMLTTP
```

The complete functionality of the AMLTTP will be discussed in detail in the accompanying
[Online user manual](http://twoears.aipa.tu-berlin.de/doc/amlttp/) very soon.


## Credits

The AMLTTP is developed by Ivo Trowitzsch and Youssef Kashef from Technische
Universitšt Berlin.


## License

The AFE is released under the [BSD 2-Clause license](https://opensource.org/licenses/BSD-2-Clause).


## Funding

This project has received funding from the European Unionís Seventh Framework
Programme for research, technological development and demonstration under grant
agreement no 618075.

![EU Flag](doc/img/eu-flag.gif) [![Tree](doc/img/tree.jpg)](http://cordis.europa.eu/fet-proactive/)
