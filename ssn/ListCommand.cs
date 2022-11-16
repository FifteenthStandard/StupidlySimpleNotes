using System.Text.RegularExpressions;

public class ListCommand : Command
{
    public ListCommand(string root)
        : base("list", "Show the contents of several notes")
    {
        var today = new Option<bool>("--today", "Show notes created today");
        var @this = new Option<string>("--this", "Show notes created this week/month/year")
            .FromAmong("week", "month", "year");
        var from = new Option<DateTime?>("--from", "Show notes created after this time");
        var to = new Option<DateTime?>("--to", "Show notes created before this time");
        var path = new Option<string>("--path", "The path to search under");

        this.Add(today);
        this.Add(@this);
        this.Add(from);
        this.Add(to);
        this.Add(path);

        this.SetHandler(async (today, @this, from, to, path) =>
        {
            var fullPath = Path.Join(root, path ?? "");

            var files = Directory.GetFiles(fullPath, "*.*", new EnumerationOptions
            {
                RecurseSubdirectories = true
            });

            if (today)
            {
                from = DateTime.Today;
                to = DateTime.MaxValue;
            }
            else if (!string.IsNullOrWhiteSpace(@this))
            {
                var date = DateTime.Today;
                switch (@this)
                {
                    case "week":
                        from = date.AddDays(1 - (int)date.DayOfWeek);
                        break;
                    case "month":
                        from = date.AddDays(1 - date.Day);
                        break;
                    case "year":
                        from = date.AddDays(1 - date.DayOfYear);
                        break;
                }
                to = DateTime.MaxValue;
            }
            else
            {
                to ??= DateTime.MaxValue;
            }

            if (string.IsNullOrWhiteSpace(path) && from == null)
            {
                Console.Error.WriteLine("Must supply either path or time range");
                Environment.Exit(1);
            }

            from ??= DateTime.MinValue;

            foreach (var file in files)
            {
                var lines = await File.ReadAllLinesAsync(file);
                var created = File.GetCreationTime(file);
                if (from <= created && created < to)
                {
                    Console.WriteLine(Path.GetRelativePath(root, file));
                    Console.WriteLine();

                    foreach (var line2 in lines)
                    {
                        Console.WriteLine(line2);
                    }
                    Console.WriteLine();
                    Console.WriteLine();
                }
            }
        }, today, @this, from, to, path);
    }
}
