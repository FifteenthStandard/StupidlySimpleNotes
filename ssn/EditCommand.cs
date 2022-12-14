public class EditCommand : Command
{
    public EditCommand(string root)
        : base("edit", "Edit the contents of a note")
    {
        var path = new Argument<string>("path", "The path for the note");

        this.Add(path);

        this.SetHandler(async (path) =>
        {
            if (!path.EndsWith(".md")) path = $"{path}.md";

            var fullPath = Path.Join(root, path);

            await Editor.Edit(fullPath);
        }, path);
    }
}
