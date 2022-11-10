using System.Diagnostics;

public class EditCommand : Command
{
    public EditCommand(string root)
        : base("edit", "Edit the contents of a note")
    {
        var path = new Argument<string>("path", "The path for the note");

        this.Add(path);

        this.SetHandler(async (path) =>
        {
            if (!path.EndsWith(".txt")) path = $"{path}.txt";

            var fullPath = Path.Join(root, path);

            var proc = Process.Start("cmd.exe", $"/c code -w {fullPath}");
            await proc.WaitForExitAsync();
        }, path);
    }
}