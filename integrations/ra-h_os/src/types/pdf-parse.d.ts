declare module 'pdf-parse' {
  interface PDFInfo {
    Title?: string;
    Author?: string;
    Creator?: string;
    Producer?: string;
    CreationDate?: string;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    [key: string]: any;
  }

  interface PDFData {
    numpages: number;
    numrender: number;
    info: PDFInfo;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    metadata: any;
    text: string;
    version: string;
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  function pdf(dataBuffer: Buffer, options?: any): Promise<PDFData>;
  
  export = pdf;
}
