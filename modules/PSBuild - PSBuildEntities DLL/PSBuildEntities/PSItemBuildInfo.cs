using System;
using System.Collections;
using System.Management.Automation;

namespace PSBuild
{
    public abstract class PSItemBuildInfo
    {
        public string Name { get; set; }
        public Version Version { get; set; }
        public string SourcePath { get; set; }
        public string DestinationPath { get; set; }

        public PSItemBuildInfo(Hashtable definition)
        {
            foreach (var dk in definition.Keys)
            {
                if ("Name".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                {
                    Name = LanguagePrimitives.ConvertTo<string>(definition[dk]);
                }
                else if ("Version".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                {
                    Version = LanguagePrimitives.ConvertTo<Version>(definition[dk]);
                }
                else if ("SourcePath".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                {
                    SourcePath = LanguagePrimitives.ConvertTo<string>(definition[dk]);
                }
                else if ("DestinationPath".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                {
                    DestinationPath = LanguagePrimitives.ConvertTo<string>(definition[dk]);
                }                
            }

            if (String.IsNullOrEmpty(this.Name)) { throw new ArgumentException("Name cannot be blank."); }
        }

        public PSItemBuildInfo(string name, Version version)
        {
            this.Name = name;
            this.Version = version;
            if (String.IsNullOrEmpty(this.Name)) { throw new ArgumentException("Name cannot be blank."); }
        }

        public PSItemBuildInfo(string name, Version version, string sourcePath, string destinationPath)
        {
            this.Name = name;
            this.Version = version;
            this.SourcePath = sourcePath;
            this.DestinationPath = destinationPath;
            if (String.IsNullOrEmpty(this.Name)) { throw new ArgumentException("Name cannot be blank."); }
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
                PSItemBuildInfo item = (PSItemBuildInfo)obj;
                return (Name == item.Name) && 
                    (Version == item.Version) && 
                    (SourcePath == item.SourcePath) &&
                    (DestinationPath == item.DestinationPath);
            }
        }

        public static bool operator ==(PSItemBuildInfo x, PSItemBuildInfo y)
        {
            return (x.Name == y.Name) &&
                (x.Version == y.Version) &&
                (x.SourcePath == y.SourcePath) &&
                (x.DestinationPath == y.DestinationPath);
        }

        public static bool operator !=(PSItemBuildInfo x, PSItemBuildInfo y)
        {
            return !(x == y);
        }

        public override string ToString()
        {
            return $"{Name} ({Version}): Source='{SourcePath}'; Destination='{DestinationPath}'";
        }

        public override int GetHashCode()
        {
            return this.ToString().GetHashCode();
        }
    }
}
