using System.Collections.ObjectModel;
using System;
using Newtonsoft.Json;

namespace PSBuildEntities
{
    public class AnalysisResult
    {
        public string CommandName { get; set; }
        public string CommandType { get; set; }
        public string CommandSource { get; set; }
        public AnalysisResultSourceLocation SourceLocation { get; set; }
        public bool IsReferenced { get; set; }
        public bool IsFound { get; set; }
        public string GetCommandFQDN()
        {
            return string.Format("{0}\\{1}", (string.IsNullOrEmpty(CommandSource) ? "" : CommandSource), CommandName);
        }

        public AnalysisResult()
        {
            SourceLocation = AnalysisResultSourceLocation.Unknown;
        }
    }

    public class AnalysisResultCollection : KeyedCollection<string, AnalysisResult>
    {
        public AnalysisResultCollection() : base (StringComparer.OrdinalIgnoreCase)
        {

        }

        protected override string GetKeyForItem(AnalysisResult item)
        {
            return item.CommandName;
        }
     
        public string ToJson()
        {
            return JsonConvert.SerializeObject(this);
        }

        public static AnalysisResultCollection FromJson(string input)
        {
            return JsonConvert.DeserializeObject<AnalysisResultCollection>(input);
        }
    }

    public enum AnalysisResultSourceLocation
    {
        Unknown,
        ProGet,
        BuildIn,
        Solution
    }

}
