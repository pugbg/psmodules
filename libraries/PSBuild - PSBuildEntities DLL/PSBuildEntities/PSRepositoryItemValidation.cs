using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Collections;

namespace PSBuild
{
    public class PSRepositoryItemValidation
    {
        public PSRepositoryItemValidation()
        {
        }

        public PSRepositoryItemValidation(Hashtable definition)
        {
            foreach (var dk in definition.Keys)
            {
                if("Dependencies".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                {
                    Dependencies = LanguagePrimitives.ConvertTo<Object[]>(definition[dk]);
                }
                else if ("Includes".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                {
                    Includes = LanguagePrimitives.ConvertTo<Hashtable>(definition[dk]);
                }
                else if ("Name".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                {
                    Name = LanguagePrimitives.ConvertTo<string>(definition[dk]);
                }
                else if ("PackageManagementProvider".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                {
                    PackageManagementProvider = LanguagePrimitives.ConvertTo<string>(definition[dk]);
                }
                else if ("Repository".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                {
                    Repository = LanguagePrimitives.ConvertTo<string>(definition[dk]);
                }
                else if ("RepositorySourceLocation".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                {
                    RepositorySourceLocation = LanguagePrimitives.ConvertTo<string>(definition[dk]);
                }
                else if ("Type".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                {
                    Type = LanguagePrimitives.ConvertTo<string>(definition[dk]);
                }
                else if ("Version".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                {
                    Version = LanguagePrimitives.ConvertTo<Version>(definition[dk]);
                }
                else if ("Priority".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                {
                    int p = 0;
                    LanguagePrimitives.TryConvertTo<int>(definition[dk], out p);
                    Priority = p;
                }
                else if ("Credential".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                {
                    Credential = LanguagePrimitives.ConvertTo<PSCredential>(definition[dk]);
                }
            }

            if (String.IsNullOrEmpty(this.Name)) { throw new ArgumentException("Name cannot be blank."); }
        }

        public Object[] Dependencies { get; set; }
        public Hashtable Includes { get; set; }
        public string Name { get; set; }
        public string PackageManagementProvider { get; set; }
        public string Repository { get; set; }
        public string RepositorySourceLocation { get; set; }
        public string Type { get; set; }
        public Version Version { get; set; }
        public int Priority { get; set; }
        public PSCredential Credential { get; set; }
        public override string ToString()
        {
            return $"{this.Name}/{this.Version}";
        }

    }
}
