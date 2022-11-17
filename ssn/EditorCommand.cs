public class EditorCommand : Command
{
    public EditorCommand()
        : base("editor", "Get or set the default editor")
    {
        var command = new Argument<string>("command", "Path to editor and any arguments")
        {
            Arity = ArgumentArity.ZeroOrOne
        };

        this.Add(command);

        this.SetHandler(async (command) =>
        {
            if (string.IsNullOrWhiteSpace(command))
            {
                Console.WriteLine(await Editor.Get());
            }
            else
            {
                await Editor.Set(command);
            }
        }, command);
    }
}
