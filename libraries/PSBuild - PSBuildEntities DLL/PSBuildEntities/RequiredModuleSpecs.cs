using System;
using System.Management.Automation;


namespace PSBuild
{
    public class RequiredModuleSpecs
    {
        public RequiredModuleSpecs()
        {
        }

        public RequiredModuleSpecs(string name)
        {
            Name = name;
        }

        public RequiredModuleSpecs(PSModuleInfo moduleInfo)
        {
            Name = moduleInfo.Name;
            Version = moduleInfo.Version;
            Guid = moduleInfo.Guid;
        }
        public RequiredModuleSpecs(PSModuleInfo moduleInfo, string targetDir)
        {
            Name = moduleInfo.Name;
            Version = moduleInfo.Version;
            Guid = moduleInfo.Guid;
            TargetDirectory = targetDir;
        }

        public RequiredModuleSpecs(Microsoft.PowerShell.Commands.ModuleSpecification moduleSpec, string targetDir)
        {
            Name = moduleSpec.Name;
            Version = moduleSpec.Version;
            Guid = moduleSpec.Guid;
            TargetDirectory = targetDir;
        }

        public string Name { get; set; }
        public Guid? Guid { get; set; }
        public Version Version { get; set; }
        public string TargetDirectory { get; set; }
        public PSRepositoryItemValidation SourceInformation { get; set; }

        public override string ToString()
        {
            return $"{Name}/{Version}";
        }
    }
   
}
