using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace PSBuild
{
    public class PSScriptBuildInfo : PSItemBuildInfo
    {
        public string RequiredModulesDestinationPath { get; set; }

        public PSScriptBuildInfo(Hashtable definition) : base(definition)
        {
            foreach (var dk in definition.Keys)
            {
                if ("RequiredModulesDestinationPath".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                {
                    RequiredModulesDestinationPath = LanguagePrimitives.ConvertTo<string>(definition[dk]);
                }
            }
        }

        public PSScriptBuildInfo(string name, Version version) : base(name, version)
        {
        }

        public PSScriptBuildInfo(string name, Version version, string sourcePath, string destinationPath) : base(name, version, sourcePath, destinationPath)
        {
        }

        public static bool operator ==(PSScriptBuildInfo x, PSScriptBuildInfo y)
        {
            return (x.Name == y.Name) &&
                (x.Version == y.Version) &&
                (x.SourcePath == y.SourcePath) &&
                (x.RequiredModulesDestinationPath == y.RequiredModulesDestinationPath) &&
                (x.DestinationPath == y.DestinationPath);
        }

        public static bool operator !=(PSScriptBuildInfo x, PSScriptBuildInfo y)
        {
            return !(x == y);
        }
        public override bool Equals(Object obj)
        {
            //Check for null and compare run-time types.
            if ((obj == null) || !this.GetType().Equals(obj.GetType()))
            {
                return false;
            }
            else
            {
                PSScriptBuildInfo item = (PSScriptBuildInfo)obj;
                return (Name == item.Name) &&
                    (Version == item.Version) &&
                    (SourcePath == item.SourcePath) &&
                    (DestinationPath == item.DestinationPath);
            }
        }

        public override int GetHashCode()
        {
            return base.GetHashCode();
        }
    }
}
