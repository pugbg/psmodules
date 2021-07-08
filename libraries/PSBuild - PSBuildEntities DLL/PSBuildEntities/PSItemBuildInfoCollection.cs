using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace PSBuild
{
    public class PSItemBuildInfoCollection<T> : List<T>
        where T : PSItemBuildInfo
    {
        public PSItemBuildInfoCollection():base(64)
        {
        }

        public new bool Contains(T item)
        {
            if ((Object)item == null)
                throw new ArgumentNullException("item");

            for (int i = 0; i < this.Count; i++)
            {
                if (item.Equals(this[i]))
                {
                    return true;
                }
            }
            return false;
        }

        public bool Contains(Hashtable requirements)
        {
            if(requirements == null)
            {
                throw new ArgumentNullException("requirements");
            }

            IQueryable<PSItemBuildInfo> query = this.AsQueryable();
            var atleastonequery = false;
            foreach (var dk in requirements.Keys)
            {
                if ("Name".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                {
                    query = query.Where(x1 => x1.Name.Equals(LanguagePrimitives.ConvertTo<string>(requirements[dk]), StringComparison.OrdinalIgnoreCase));
                    atleastonequery = true;
                }
                else if ("Version".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                {
                    query = query.Where(x2 => x2.Version == LanguagePrimitives.ConvertTo<Version>(requirements[dk]));
                    atleastonequery = true;
                }
                else if ("SourcePath".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                {
                    query = query.Where(x3 => $"{x3.SourcePath}".Equals(LanguagePrimitives.ConvertTo<string>(requirements[dk]), StringComparison.OrdinalIgnoreCase));
                    atleastonequery = true;
                }
                else if ("DestinationPath".Equals(dk.ToString(), StringComparison.OrdinalIgnoreCase))
                {
                    query = query.Where(x4 => $"{x4.DestinationPath}".Equals(LanguagePrimitives.ConvertTo<string>(requirements[dk]), StringComparison.OrdinalIgnoreCase));
                    atleastonequery = true;
                }
            }

            if (!atleastonequery)
            {
                throw new ArgumentException("The requirements Hashtable must contain at least one valid filtering property.");
            }

            return query.Any();
        }

        public bool Contains(string name)
        {
            return this.Any(x => x.Name.Equals(name, StringComparison.OrdinalIgnoreCase));
        }

        public bool Contains(string name, Version version)
        {
            return this.Any(x => x.Name.Equals(name, StringComparison.OrdinalIgnoreCase) && x.Version == version);
        }

        public T GetLatestVersion(string name)
        {
            if (String.IsNullOrEmpty(name)) { return null; }

            var list = new List<T>();
            foreach (var item in this)
            {
                if (name.Equals(item.Name, StringComparison.OrdinalIgnoreCase))
                {
                    list.Add(item);
                }
            }

            if (list.Count == 0) { return null; }
            if (list.Count == 1) { return list[0]; }

            return (list.OrderByDescending(o => o.Version)).FirstOrDefault();
        }
    }
}
