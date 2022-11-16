public class GetCommand : Command
{
    public GetCommand(string root)
        : base("get", "Show the contents of a note")
    {
        var path = new Argument<string>("path", "The path for the note");

        this.Add(path);

        this.SetHandler(async (path) =>
        {
            if (!path.EndsWith(".txt")) path = $"{path}.txt";

            var fullPath = Path.Join(root, path);

            var note = await File.ReadAllTextAsync(fullPath);
            Console.WriteLine(note);
        }, path);
    }
}
