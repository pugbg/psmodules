using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Collections;

namespace PSBuild
{
    public class CheckCommandReferencesConfiguration
    {
        public bool Enabled { get; set; }
        public List<string> ExcludedSources { get; set; }
        public List<string> ExcludedCommands { get; set; }

        public CheckCommandReferencesConfiguration()
        {
            this.ExcludedSources = new List<string>();
            this.ExcludedCommands = new List<string>();
        }

        public CheckCommandReferencesConfiguration(Hashtable definition)
        {
            this.ExcludedSources = new List<string>();
            this.ExcludedCommands = new List<string>();

            foreach (var dk in definition.Keys)
            {
                if ("Enabled".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                {
                    Enabled = LanguagePrimitives.ConvertTo<bool>(definition[dk]);
                }
                else if ("ExcludedSources".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                {
                    ExcludedSources.AddRange(LanguagePrimitives.ConvertTo<string[]>(definition[dk]));
                }
                else if ("ExcludedCommands".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                {
                    ExcludedCommands.AddRange(LanguagePrimitives.ConvertTo<string[]>(definition[dk]));
                }
            }

        }


    }

}
