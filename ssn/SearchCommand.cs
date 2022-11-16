using System.Text.RegularExpressions;

public class SearchCommand : Command
{
    public SearchCommand(string root)
        : base("search", "Search for notes")
    {
        var path = new Option<string>("--path", "The path to search under");
        var search = new Argument<string[]>("search", "The pattern to search for");

        this.Add(path);
        this.Add(search);

        this.SetHandler(async (path, search) =>
        {
            var fullPath = Path.Join(root, path ?? "");

            var files = Directory.GetFiles(fullPath, "*.*", new EnumerationOptions
            {
                RecurseSubdirectories = true
            });

            var matcher = new Regex(string.Join(' ', search));

            foreach (var file in files)
            {
                var lines = await File.ReadAllLinesAsync(file);
                foreach (var line in lines)
                {
                    if (matcher.IsMatch(line))
                    {
                        Console.WriteLine(Path.GetRelativePath(root, file));
                        Console.WriteLine();

                        foreach (var line2 in lines)
                        {
                            Console.WriteLine(line2);
                        }
                        Console.WriteLine();
                        Console.WriteLine();
                        break;
                    }
                }
            }
        }, path, search);
    }
}
