require 'rubygems'    

sh "bundle install --system"
Gem.clear_paths

require 'albacore'
require 'rake/clean'
require 'set'

include FileUtils

solution_file = FileList["*.sln"].first
build_file = FileList["*.msbuild"].first
www_proj_file = FileList["**/MavenThought.PrDc.Demo/*.csproj"].first

begin
	require 'git' 
	commit = Git.open(".").log.first.sha[0..10]
rescue
	commit = 'na'
	puts "Git not available"
end

project_name = "MavenThought.PrDc.Demo"
version = IO.readlines('VERSION')[0] rescue "0.0.0.0"
build_folder = File.join('.', 'build', 'www')

CLEAN.include("main/**/bin", "main/**/obj", "test/**/obj", "test/**/bin", "build")

CLOBBER.include("_Re*", "packages", "**/*.user", "**/*.cache", "**/*.suo", "*.docstate*", "Test*.xml")

desc 'Default build'
task :default => ["build:all"]

desc 'Setup requirements to build and deploy'
task :setup => ["setup:dep", "setup:os"]

desc "Alias for deploy:local"
task :deploy => ["deploy:local"]

desc "Run all unit tests"
task :test => ["test:unit"]

namespace :setup do
	desc "Setup dependencies for nuget packages"
	task :dep do
		FileList["**/packages.config"].each do |file|
			sh "nuget install #{file} /OutputDirectory Packages"
		end

	end

	desc "Setup dependencies for this OS (x86/x64)"
	task :os => ["setup:dep"] do
		setup_os
	end
end

namespace :build do

	desc "Build the project"
	msbuild :all, [:config] => ["setup"] do |msb, args|
		msb.properties :configuration => args[:config] || :Debug
		msb.targets :Build
		msb.solution = solution_file
	end

	desc "Rebuild the project"
	task :re => ["clean", "build:all"]
end

namespace :test do

	desc "Run unit tests"
	nunit :unit => ["build:all"] do |nunit|
		nunit.command = "packages/NUnit.2.5.9.10348/Tools/nunit-console.exe"
		nunit.assemblies FileList["test/unit/**/bin/debug/*Tests.dll"]
	end

	desc "Run acceptance tests"
	nunit :acceptance, [:tag] => ["deploy:local"] do |nunit, args|
		nunit.command = "packages/NUnit.2.5.9.10348/Tools/nunit-console.exe"
		nunit.options "/include #{args.tag}" unless ( args.tag.nil? )
		nunit.assemblies FileList["test/acceptance/**/bin/debug/*Tests.dll"]
	end
end
namespace :deploy do
	
	desc "Publish the site to a local build folder (via an MSBuild Publish target)"
	msbuild :local, :config do |msb, args|

		# set a default configuration
		configuration = args[:config] || :Debug

		# construct the absolute folder path to build_folder
		complete_build_folder = File.expand_path(build_folder)

		puts "Publish build locally to #{complete_build_folder}"

		# clean out the build folder
		puts "Removing '#{complete_build_folder}'..." if File.directory? complete_build_folder
		rm_rf(complete_build_folder) if File.directory? complete_build_folder

		# ensure the build folder exists
		puts "Creating '#{complete_build_folder}'..." unless File.directory? complete_build_folder
		FileUtils.mkdir_p(complete_build_folder) unless File.directory? complete_build_folder

		# window-ize the paths
		webprojoutdir = complete_build_folder.gsub('/', '\\')
		bindir =  "#{complete_build_folder}/bin//".gsub('/', '\\')

		puts
		puts "Packaging as '#{configuration}'"
		puts "----------------------------------"
		puts "site to: '#{webprojoutdir}'"
		puts "bins to: '#{bindir}'"
		puts 

		msb.targets :ResolveReferences,:_CopyWebApplication
		msb.properties(
			:configuration => configuration,
			:webprojectoutputdir => webprojoutdir,
			:outdir => bindir
		)
		msb.solution = www_proj_file
	end	  
end

namespace :util do
	task :clean_folder, :folder do |t, args|
		rm_rf(args.folder)
		Dir.mkdir(args.folder) unless File.directory? args.folder
	end		
end

def setup_os(target = nil)
	target ||= File.exist?('c:\Program Files (x86)') ? 64 : 32
	#puts "**** Setting up OS #{target} bits"
	#files = FileList["Packages/SQLitex64.1.0.66/lib/#{target}/*.dll"].first
	#puts "**** Using #{files}"
	#FileUtils.cp(files, "Packages/SQLitex64.1.0.66/lib/")
end

