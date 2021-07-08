using System;
using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json;
using System.Collections.ObjectModel;

namespace PSBuild
{
    public class PSRepositoryItemValidationCollection : List<PSRepositoryItemValidation>
    {
        public PSRepositoryItemValidationCollection() : base(64)
        {
        }

        public new bool Contains(PSRepositoryItemValidation item)
        {
            return this.Any(x => 
                x.Name.Equals(item.Name, StringComparison.OrdinalIgnoreCase) 
                && x.Version == item.Version
                && x.Repository == item.Repository);
        }

        public bool Contains(string name)
        {
            return this.Any(x => x.Name.Equals(name, StringComparison.OrdinalIgnoreCase));
        }

        public bool Contains(string name, Version version)
        {
            return this.Any(x => x.Name.Equals(name, StringComparison.OrdinalIgnoreCase) && x.Version == version);
        }
    }

}
