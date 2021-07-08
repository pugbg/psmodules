using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;

namespace PSBuild
{
    public class PSScriptInfo
    {
        public string Name { get; set; }
        public Version Version { get; set; }
        public Guid? Guid { get; set; }
        public string Path { get; set; }
        public string ScriptBase { get; set; }
        public string Description { get; set; }
        public string Author { get; set; }
        public string CompanyName { get; set; }
        public List<RequiredModuleSpecs> RequiredModules { get; set; }
        public string[] ExternalModuleDependencies { get; set; }
        public object PrivateData { get; set; }

        //    public string Copyright { get; set; }
        //    public object Tags { get; set; }
        //    public string ReleaseNotes { get; set; }
        //    public object RequiredScripts { get; set; }
        //    public object ExternalScriptDependencies { get; set; }
        //    public object LicenseUri { get; set; }
        //    public object ProjectUri { get; set; }
        //    public object IconUri { get; set; }
        //    public object DefinedCommands { get; set; }
        //    public object DefinedFunctions { get; set; }
        //    public object DefinedWorkflows { get; set; }

        public PSScriptInfo(Hashtable definition)
        {
            this.RequiredModules = new List<RequiredModuleSpecs>();
            this.ExternalModuleDependencies = new string[0];

            foreach (var dk in definition.Keys)
            {
                if (definition[dk] != null)
                {
                    if ("Name".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                    {
                        Name = LanguagePrimitives.ConvertTo<string>(definition[dk]);
                    }
                    else if ("Version".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                    {
                        Version = LanguagePrimitives.ConvertTo<Version>(definition[dk]);
                    }
                    else if ("Guid".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                    {
                        Guid = LanguagePrimitives.ConvertTo<Guid?>(definition[dk]);
                    }
                    else if ("Path".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                    {
                        Path = LanguagePrimitives.ConvertTo<string>(definition[dk]);
                    }
                    else if ("ScriptBase".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                    {
                        ScriptBase = LanguagePrimitives.ConvertTo<string>(definition[dk]);
                    }
                    else if ("Description".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                    {
                        Description = LanguagePrimitives.ConvertTo<string>(definition[dk]);
                    }
                    else if ("Author".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                    {
                        Author = LanguagePrimitives.ConvertTo<string>(definition[dk]);
                    }
                    else if ("CompanyName".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                    {
                        CompanyName = LanguagePrimitives.ConvertTo<string>(definition[dk]);
                    }
                    else if ("RequiredModules".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                    {
                        var reqM = LanguagePrimitives.ConvertTo<Microsoft.PowerShell.Commands.ModuleSpecification[]>(definition[dk]);
                        foreach (var item in reqM)
                        {
                            RequiredModules.Add(new RequiredModuleSpecs(item, null));
                        }
                    }
                    else if ("ExternalModuleDependencies".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                    {
                        ExternalModuleDependencies = LanguagePrimitives.ConvertTo<string[]>(definition[dk]);
                    }
                    else if ("PrivateData".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                    {
                        PrivateData = LanguagePrimitives.ConvertTo<string>(definition[dk]);
                    }
                }
            }

            if (String.IsNullOrEmpty(this.Name)) { throw new ArgumentException("Name cannot be blank."); }
            if (String.IsNullOrEmpty(this.Path)) { throw new ArgumentException("Path cannot be blank."); }
            if (String.IsNullOrEmpty(this.ScriptBase)) { throw new ArgumentException("ScriptBase cannot be blank."); }
        }

        public override string ToString()
        {
            var verStr = $"{Version}";
            if(string.IsNullOrWhiteSpace(verStr))
            {
                return $"{Name}";
            }
            else
            {
                return $"{Name} ({verStr})";
            }
        }
    }
}
