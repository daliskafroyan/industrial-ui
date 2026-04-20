import { DownloadIcon } from "lucide-react";
import { Button } from "@/registry/default/ui/button";

export default function Particle() {
  return (
    <Button>
      Download
      <DownloadIcon aria-hidden="true" />
    </Button>
  );
}
