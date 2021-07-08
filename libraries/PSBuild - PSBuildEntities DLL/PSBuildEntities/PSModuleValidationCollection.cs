using System;
using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json;
using System.Collections.ObjectModel;

namespace PSBuild
{
    public class PSModuleValidationCollection : KeyedCollection<string, PSModuleValidation>
    {
        public PSModuleValidationCollection() : base(StringComparer.OrdinalIgnoreCase)
        {
        }

        protected override string GetKeyForItem(PSModuleValidation item)
        {
            return item.ModuleName;
        }

        public string ToJson()
        {
            return JsonConvert.SerializeObject(this);
        }

        public static CommandInfoCollection FromJson(string input)
        {
            return JsonConvert.DeserializeObject<CommandInfoCollection>(input);
        }

        public string[] AllModuleNames
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

        public bool TryAdd(PSModuleValidation item)
        {
            if (!this.Contains(item.ModuleName))
            {
                this.Add(item);
                return true;
            }
            else
            {
                return false;
            }
        }

        public new void Add(PSModuleValidation item)
        {
            item.ParentCollection = this;
            base.Add(item);
        }

        public void Update(PSModuleValidation item)
        {
            if (!this.Contains(item.ModuleName))
            {
                this.Add(item);
            }
            else
            {
                this[item.ModuleName].Update(item);
            }
        }

        public void RefreshCollectionPreferredProcessingOrder()
        {
            foreach (var item in this)
            {
                item.PreferredProcessingOrder = item.GetPreferredProcessingOrder();
            }
        }

        public PSModuleValidation[] GetOrderedProcessingList()
        {
            RefreshCollectionPreferredProcessingOrder();

            return this.OrderBy(x => x.PreferredProcessingOrder).ToArray();
        }
    }

}
