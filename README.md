Format Transformation Service
=============================

* The transformation service performs the format transformation on a given url. The url should contain a 
  transformation identifier which is used to look up the defined transformation instruction, and optionally 
  a source file for the transformation. 
* The transformation identifier is then used to look up the actual transformation 
  instruction in the config file i.e., transform.xml.
* The transformation service then performs the format transformation, locally cache the created files 
  with proper file extension and send back the link(s) of the created file(s).  The transformation service
  would also return associated premis event and agent to record the result of the transformation and the software
  that is used for the transformation.
* The calling client would parse the return links to retrieve the created files.
* Once the created file(s) are retrieved by the calling clients, the local caches for the files are removed.

Quickstart
==========
	1. Retrieve a copy of the trasnformation service.  You can either create a local git clone of the transformation service, ex.
	%git clone git://github.com/daitss/transform.git
	or download a copy from the download page.

	2. Install all the required gems according to the Gemfile in this project
	% bundle install
	
	3. Test the installation via the test harness. 
	% bundle exec cucumber feature/*

	4. Run the description srvice with thin (use "thin --help" to get additional information on using thin)
	% bundle exec thin start

Requirement
-----------
* ruby (tested on 1.8.6 and 1.8.7)
* cucumber (gem)
* libxml-ruby (gem)
* log4r (gem)
* sinatra (gem) - a minimal web application framework.  It will work with any web server such as mongrel, thin, apache etc.
* install any desired tools (such as ffmpeg, libquicktime, ghostscript, mencoder, etc) on your system.  The
  config/transform.xml contains default setup to use those tools.

License
-------
GNU General Public License

Directory Structure
-------------------
* config: configuration files.  It currently only contains transform.xml which provide instructions on using
  desired tools for file format transformation.
* feature: cucumber feature files
* files: contain test files for test harness. These files are for testing only and can be deleted after deployment.
* lib: ruby source code

Usage
-----
* Use http GET method with a location parameter pointing to the FILE url of the intended file and a 
  transformation identifier defined in transform.xml
  For example, if using curl
	curl http://transformation.fda.edu/transform/WAVE_NORM?location=file:///Users/Dummy/testdata/audio/wave/stereol.wav
	where the WAVE_NORM is the transformation identifier and "/Users/Dummy/testdata/audio/wave/stereol.wav" 
	is the file to be transformed.

* Use http GET method with a location parameter pointing to the http url of the intended resource.
  For example, if using curl
 	curl http://transformation.fda.edu/transform/WAVE_NORM?location=http://www.fcla.edu/daitss-test/files/GLASS.WAV
	where the WAVE_NORM is the transformation identifier and "http://www.fcla.edu/daitss-test/files/GLASS.WAV" 
	is the URL resource to be transformed.

HTTP return code
----------------
* 200 - successful.
* 400 - missing the transformation identifier. The request does not specify a transformation identifier.
* 404 - not found. Cannot locate the specified source file
* 500 - Service Error, encounter errors during transformation process.
* 501 - Cannot locate the transformation instruction on the given transformation identifier.

	
Documentation
-------------
[development wiki](http://wiki.github.com/daitss/transform/)