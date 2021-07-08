using System;
using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json;
using System.Collections.ObjectModel;

namespace PSBuild
{
    public class PSScriptValidationCollection : KeyedCollection<string, PSScriptValidation>
    {
        public PSScriptValidationCollection() : base(StringComparer.OrdinalIgnoreCase)
        {
        }

        protected override string GetKeyForItem(PSScriptValidation item)
        {
            return item.ScriptPath;
        }

        public string[] AllScripts
        {
            get
            {
                if (this.Dictionary != null)
                {
                    return this.Dictionary.Keys.ToArray();
                }
                else
                {
                    return this.Select(this.GetKeyForItem).ToArray();
                }
            }
        }

        public bool TryAdd(PSScriptValidation item)
        {
            if (!this.Contains(item.ScriptPath))
            {
                this.Add(item);
                return true;
            }
            else
            {
                return false;
            }
        }

        public new void Add(PSScriptValidation item)
        {
            item.ParentCollection = this;
            base.Add(item);
        }

        public void Update(PSScriptValidation item)
        {
            if (!this.Contains(item.ScriptPath))
            {
                this.Add(item);
            }
            else
            {
                this[item.ScriptPath].Update(item);
            }
        }

    }

}
