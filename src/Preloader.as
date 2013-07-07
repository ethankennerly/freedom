/**
 * Quote from: racter on Thu, Jun 10, 2010
 *     My project layout is usually to have the Preloader.as file in the root of the source path (one level up from 'Shooter' for you), and then refer to the Main class with its full qualified path (classname="Shooter.Main" in your case) .
 *
 * This worked like a charm, thanks a lot
 * http://forums.flixel.org/index.php?topic=1781.0
 */ 
package
{
    import org.flixel.system.FlxPreloader;

    public class Preloader extends FlxPreloader
    {
        public function Preloader()
        {
            className = "com.finegamedesign.freedom.Main";
            super();
        }
    }
}
