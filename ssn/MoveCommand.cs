public class MoveCommand : Command
{
    public MoveCommand(string root)
        : base("move", "Move or rename a note")
    {
        var path = new Argument<string>("path", "The path for the note");
        var destination = new Argument<string>("destination", "The new path for the note");

        this.Add(path);
        this.Add(destination);

        this.SetHandler((path, destination) =>
        {
            if (!path.EndsWith(".txt")) path = $"{path}.txt";
            if (!destination.EndsWith(".txt")) destination = $"{destination}.txt";

            var fullPath = Path.Join(root, path);

            File.Move(
                Path.Join(root, path),
                Path.Join(root, destination));
        }, path, destination);
    }
}