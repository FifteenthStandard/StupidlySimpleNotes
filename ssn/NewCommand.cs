using System.Text;

public class NewCommand : Command
{
    public NewCommand(string root)
        : base("new", "Create a new note")
    {
        var note = new Argument<string[]>("note", "The body of the note");
        var path = new Option<string>("--path", "The path for the note");
        var edit = new Option<bool>("--edit", "Edit the note before saving");

        this.Add(note);
        this.Add(path);
        this.Add(edit);

        this.SetHandler(async (note, path, edit) =>
        {
            if (string.IsNullOrWhiteSpace(path) || path.EndsWith("\\") || path.EndsWith("/"))
            {
                var ticks = (DateTime.MaxValue - DateTime.Now).Ticks;
                path = $"{path}{ticks}.md";
            }

            if (!path.EndsWith(".md")) path = $"{path}.md";

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
                await Editor.Edit(tmp);
                File.Copy(tmp, fullPath, true);
            }
            else
            {
                await File.WriteAllTextAsync(fullPath, body.ToString());
            }
        }, note, path, edit);
    }
}
