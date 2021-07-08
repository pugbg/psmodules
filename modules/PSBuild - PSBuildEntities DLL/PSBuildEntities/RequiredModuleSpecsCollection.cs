using System;
using System.Collections.Generic;
using System.Linq;
using System.Collections.ObjectModel;

namespace PSBuild
{
    public class RequiredModuleSpecsCollection : List<RequiredModuleSpecs>
    {
        public RequiredModuleSpecsCollection() : base(64)
        {
        }

        public List<RequiredModuleSpecs> GetLatestModuleVersions()
        {
            if(this.Count == 0) { return new List<RequiredModuleSpecs>(); }

            var result = new List<RequiredModuleSpecs>(this.Count);
            
            foreach (var modGrp in this.GroupBy(x => $"{x.Name}{x.TargetDirectory}", StringComparer.OrdinalIgnoreCase))
            {
                result.Add(modGrp.OrderByDescending(o => o.Version).First());
            }

            return result;
        }

        public List<RequiredModuleSpecs> GetUniqueModuleVersions()
        {
            if (this.Count == 0) { return new List<RequiredModuleSpecs>(); }

            var result = new List<RequiredModuleSpecs>(this.Count);

            foreach (var modGrp in this.GroupBy(x => $"{x.Name}{x.TargetDirectory}", StringComparer.OrdinalIgnoreCase))
            {
                HashSet<Version> seenVersions = new HashSet<Version>();
                foreach (var modVersion in modGrp)
                {
                    if (seenVersions.Add(modVersion.Version))
                    {
                        result.Add(modVersion);
                    }
                }
            }

            return result;
        }
    }

    
}
