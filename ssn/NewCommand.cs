using System.Diagnostics;
using System.Text;

public class NewCommand : Command
{
    public NewCommand(string root)
        : base("new", "Create a new note")
    {
        var path = new Option<string>("--path", "The path for the note");
        var edit = new Option<bool>("--edit", "Edit the note before saving");
        var note = new Argument<string[]>("note", "The body of the note");

        this.Add(path);
        this.Add(edit);
        this.Add(note);

        this.SetHandler(async (path, edit, note) =>
        {
            if (string.IsNullOrWhiteSpace(path))
            {
                var ticks = (DateTime.MaxValue - DateTime.Now).Ticks;
                path = $"{ticks}.txt";
            }

            if (!path.EndsWith(".txt")) path = $"{path}.txt";

            var fullPath = Path.Join(root, path);
            Directory.CreateDirectory(Path.GetDirectoryName(fullPath) ?? "");

            var body = new StringBuilder();

            var noteString = string.Join(' ', note);
            if (!string.IsNullOrWhiteSpace(noteString))
            {
                body.Append(noteString);
                body.AppendLine();
            }

            if (Console.IsInputRedirected)
            {
                body.Append(await Console.In.ReadToEndAsync());
            }

            if (edit || body.Length == 0)
            {
                var tmp = Path.GetTempFileName();
                await File.WriteAllTextAsync(tmp, body.ToString());
                var proc = Process.Start("cmd.exe", $"/c code -w {tmp}");
                await proc.WaitForExitAsync();
                File.Copy(tmp, fullPath, true);
            }
            else
            {
                await File.WriteAllTextAsync(fullPath, body.ToString());
            }
        }, path, edit, note);
    }
}
