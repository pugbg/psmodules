using System;
using System.Collections;
using System.Management.Automation;

namespace PSBuild
{
    public class PSModuleBuildInfo : PSItemBuildInfo
    {
        public bool IsPortableModule { get; set; }

        public PSModuleBuildInfo(Hashtable definition) : base(definition)
        {
            IsPortableModule = true;
            foreach (var dk in definition.Keys)
            {
                if ("IsPortableModule".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                {
                    IsPortableModule = LanguagePrimitives.ConvertTo<bool>(definition[dk]);
                }
            }
        }

        public PSModuleBuildInfo(string name, Version version) : base(name, version)
        {
            IsPortableModule = true;
        }

        public PSModuleBuildInfo(string name, Version version, string sourcePath, string destinationPath) : base(name, version, sourcePath, destinationPath)
        {
            IsPortableModule = true;
        }

        public static bool operator ==(PSModuleBuildInfo x, PSModuleBuildInfo y)
        {
            return (x.Name == y.Name) &&
                (x.Version == y.Version) &&
                (x.SourcePath == y.SourcePath) &&
                (x.DestinationPath == y.DestinationPath);
        }

        public static bool operator !=(PSModuleBuildInfo x, PSModuleBuildInfo y)
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
                PSModuleBuildInfo item = (PSModuleBuildInfo)obj;
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
